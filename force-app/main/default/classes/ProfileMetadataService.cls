public with sharing class ProfileMetadataService {

    // Cache the global describe to avoid repeated calls
    private static Map<String, Schema.SObjectType> globalDescribe;

    private static Map<String, Schema.SObjectType> getGlobalDescribe() {
        if (globalDescribe == null) {
            globalDescribe = Schema.getGlobalDescribe();
        }
        return globalDescribe;
    }

    // Get all profiles for dropdown
    public static List<ProfileComparisonModels.ProfileInfo> getAllProfiles() {
        List<ProfileComparisonModels.ProfileInfo> profiles = new List<ProfileComparisonModels.ProfileInfo>();

        for (Profile p : [SELECT Id, Name, UserLicense.Name FROM Profile ORDER BY Name]) {
            ProfileComparisonModels.ProfileInfo info = new ProfileComparisonModels.ProfileInfo();
            info.profileId = p.Id;
            info.profileName = p.Name;
            info.userLicenseName = p.UserLicense != null ? p.UserLicense.Name : null;
            profiles.add(info);
        }

        return profiles;
    }

    // Get the PermissionSet Id for a Profile (Profiles are stored as PermissionSets internally)
    public static String getPermissionSetIdForProfile(String profileId) {
        List<PermissionSet> psList = [
            SELECT Id
            FROM PermissionSet
            WHERE IsOwnedByProfile = true AND ProfileId = :profileId
            LIMIT 1
        ];
        return psList.isEmpty() ? null : psList[0].Id;
    }

    // Get complete profile metadata
    public static ProfileComparisonModels.ProfileMetadata getProfileMetadata(String profileId) {
        ProfileComparisonModels.ProfileMetadata metadata = new ProfileComparisonModels.ProfileMetadata();

        // Get basic profile info
        Profile p = [SELECT Id, Name FROM Profile WHERE Id = :profileId];
        metadata.profileId = p.Id;
        metadata.profileName = p.Name;
        metadata.permissionSetId = getPermissionSetIdForProfile(profileId);

        if (metadata.permissionSetId == null) {
            metadata.assignedApps = new List<ProfileComparisonModels.AppAccess>();
            metadata.objectPermissions = new List<ProfileComparisonModels.ObjectPermission>();
            metadata.systemPermissions = new List<ProfileComparisonModels.SystemPermission>();
            metadata.apexClassAccess = new List<ProfileComparisonModels.EntityAccess>();
            metadata.vfPageAccess = new List<ProfileComparisonModels.EntityAccess>();
            metadata.customPermissions = new List<ProfileComparisonModels.EntityAccess>();
            return metadata;
        }

        // Get all permission types
        metadata.assignedApps = getAssignedApps(metadata.permissionSetId);
        metadata.objectPermissions = getObjectPermissions(metadata.permissionSetId);
        metadata.systemPermissions = getSystemPermissions(metadata.permissionSetId);
        metadata.apexClassAccess = getApexClassAccess(metadata.permissionSetId);
        metadata.vfPageAccess = getVfPageAccess(metadata.permissionSetId);
        metadata.customPermissions = getCustomPermissions(metadata.permissionSetId);

        return metadata;
    }

    // Get assigned apps using SetupEntityAccess for AppMenuItem
    private static List<ProfileComparisonModels.AppAccess> getAssignedApps(String permSetId) {
        List<ProfileComparisonModels.AppAccess> apps = new List<ProfileComparisonModels.AppAccess>();

        // Query SetupEntityAccess for connected/custom apps
        Map<Id, SetupEntityAccess> appAccessMap = new Map<Id, SetupEntityAccess>();
        for (SetupEntityAccess sea : [
            SELECT SetupEntityId, SetupEntity.Name
            FROM SetupEntityAccess
            WHERE ParentId = :permSetId
            AND SetupEntityType = 'TabSet'
        ]) {
            appAccessMap.put(sea.SetupEntityId, sea);
        }

        // Also query AppMenuItem for all available apps
        for (AppMenuItem ami : [
            SELECT Id, Name, Label, ApplicationId, Type
            FROM AppMenuItem
            WHERE IsAccessible = true
            ORDER BY Label
        ]) {
            ProfileComparisonModels.AppAccess app = new ProfileComparisonModels.AppAccess();
            app.appName = ami.Name;
            app.appLabel = ami.Label;
            app.isVisible = appAccessMap.containsKey(ami.ApplicationId);
            app.isDefault = false;
            apps.add(app);
        }

        // If no AppMenuItem results, fall back to SetupEntityAccess data
        if (apps.isEmpty() && !appAccessMap.isEmpty()) {
            for (SetupEntityAccess sea : appAccessMap.values()) {
                ProfileComparisonModels.AppAccess app = new ProfileComparisonModels.AppAccess();
                app.appName = sea.SetupEntity.Name;
                app.appLabel = sea.SetupEntity.Name;
                app.isVisible = true;
                app.isDefault = false;
                apps.add(app);
            }
        }

        return apps;
    }

    // Get object permissions
    private static List<ProfileComparisonModels.ObjectPermission> getObjectPermissions(String permSetId) {
        List<ProfileComparisonModels.ObjectPermission> objPerms = new List<ProfileComparisonModels.ObjectPermission>();

        for (ObjectPermissions op : [
            SELECT SobjectType, PermissionsCreate, PermissionsRead, PermissionsEdit,
                   PermissionsDelete, PermissionsViewAllRecords, PermissionsModifyAllRecords
            FROM ObjectPermissions
            WHERE ParentId = :permSetId
            ORDER BY SobjectType
        ]) {
            ProfileComparisonModels.ObjectPermission objPerm = new ProfileComparisonModels.ObjectPermission();
            objPerm.objectName = op.SobjectType;
            objPerm.objectLabel = getObjectLabel(op.SobjectType);
            objPerm.canCreate = op.PermissionsCreate;
            objPerm.canRead = op.PermissionsRead;
            objPerm.canEdit = op.PermissionsEdit;
            objPerm.canDelete = op.PermissionsDelete;
            objPerm.canViewAll = op.PermissionsViewAllRecords;
            objPerm.canModifyAll = op.PermissionsModifyAllRecords;
            objPerm.fieldPermissions = new List<ProfileComparisonModels.FieldPermission>();
            objPerms.add(objPerm);
        }

        return objPerms;
    }

    // Get field permissions for a specific object (lazy loaded)
    public static List<ProfileComparisonModels.FieldPermission> getFieldPermissions(String permSetId, String objectName) {
        List<ProfileComparisonModels.FieldPermission> fieldPerms = new List<ProfileComparisonModels.FieldPermission>();

        for (FieldPermissions fp : [
            SELECT Field, SobjectType, PermissionsRead, PermissionsEdit
            FROM FieldPermissions
            WHERE ParentId = :permSetId AND SobjectType = :objectName
            ORDER BY Field
        ]) {
            ProfileComparisonModels.FieldPermission fieldPerm = new ProfileComparisonModels.FieldPermission();
            fieldPerm.fieldName = fp.Field;
            fieldPerm.fieldLabel = getFieldLabel(fp.SobjectType, fp.Field);
            fieldPerm.canRead = fp.PermissionsRead;
            fieldPerm.canEdit = fp.PermissionsEdit;
            fieldPerms.add(fieldPerm);
        }

        return fieldPerms;
    }

    // Get system/app permissions dynamically from PermissionSet fields
    private static List<ProfileComparisonModels.SystemPermission> getSystemPermissions(String permSetId) {
        List<ProfileComparisonModels.SystemPermission> sysPerms = new List<ProfileComparisonModels.SystemPermission>();

        // Get all fields on PermissionSet that start with "Permissions"
        Map<String, Schema.SObjectField> psFields = Schema.SObjectType.PermissionSet.fields.getMap();
        List<String> permFieldNames = new List<String>();

        for (String fieldName : psFields.keySet()) {
            if (fieldName.startsWithIgnoreCase('permissions')) {
                permFieldNames.add(fieldName);
            }
        }

        if (permFieldNames.isEmpty()) {
            return sysPerms;
        }

        // Build dynamic SOQL to query all permission fields
        String soql = 'SELECT ' + String.join(permFieldNames, ', ') + ' FROM PermissionSet WHERE Id = :permSetId';
        List<PermissionSet> results = Database.query(soql);

        if (results.isEmpty()) {
            return sysPerms;
        }

        PermissionSet ps = results[0];

        // Build the list of system permissions
        for (String fieldName : permFieldNames) {
            Schema.DescribeFieldResult dfr = psFields.get(fieldName).getDescribe();
            Object val = ps.get(fieldName);

            if (val instanceof Boolean) {
                ProfileComparisonModels.SystemPermission sp = new ProfileComparisonModels.SystemPermission();
                // Remove the "Permissions" prefix for display name
                sp.permissionName = fieldName.removeStartIgnoreCase('permissions');
                sp.permissionLabel = dfr.getLabel();
                sp.isEnabled = (Boolean) val;
                sysPerms.add(sp);
            }
        }

        // Sort by label
        sysPerms.sort();

        return sysPerms;
    }

    // Get Apex class access
    private static List<ProfileComparisonModels.EntityAccess> getApexClassAccess(String permSetId) {
        List<ProfileComparisonModels.EntityAccess> access = new List<ProfileComparisonModels.EntityAccess>();

        for (SetupEntityAccess sea : [
            SELECT SetupEntityId, SetupEntity.Name
            FROM SetupEntityAccess
            WHERE ParentId = :permSetId AND SetupEntityType = 'ApexClass'
            ORDER BY SetupEntity.Name
        ]) {
            ProfileComparisonModels.EntityAccess ea = new ProfileComparisonModels.EntityAccess();
            ea.entityId = sea.SetupEntityId;
            ea.entityName = sea.SetupEntity.Name;
            ea.hasAccess = true;
            access.add(ea);
        }

        return access;
    }

    // Get VF page access
    private static List<ProfileComparisonModels.EntityAccess> getVfPageAccess(String permSetId) {
        List<ProfileComparisonModels.EntityAccess> access = new List<ProfileComparisonModels.EntityAccess>();

        for (SetupEntityAccess sea : [
            SELECT SetupEntityId, SetupEntity.Name
            FROM SetupEntityAccess
            WHERE ParentId = :permSetId AND SetupEntityType = 'ApexPage'
            ORDER BY SetupEntity.Name
        ]) {
            ProfileComparisonModels.EntityAccess ea = new ProfileComparisonModels.EntityAccess();
            ea.entityId = sea.SetupEntityId;
            ea.entityName = sea.SetupEntity.Name;
            ea.hasAccess = true;
            access.add(ea);
        }

        return access;
    }

    // Get custom permission access
    private static List<ProfileComparisonModels.EntityAccess> getCustomPermissions(String permSetId) {
        List<ProfileComparisonModels.EntityAccess> access = new List<ProfileComparisonModels.EntityAccess>();

        for (SetupEntityAccess sea : [
            SELECT SetupEntityId, SetupEntity.Name
            FROM SetupEntityAccess
            WHERE ParentId = :permSetId AND SetupEntityType = 'CustomPermission'
            ORDER BY SetupEntity.Name
        ]) {
            ProfileComparisonModels.EntityAccess ea = new ProfileComparisonModels.EntityAccess();
            ea.entityId = sea.SetupEntityId;
            ea.entityName = sea.SetupEntity.Name;
            ea.hasAccess = true;
            access.add(ea);
        }

        return access;
    }

    // Helper to get object label
    private static String getObjectLabel(String objectName) {
        try {
            Schema.SObjectType sot = getGlobalDescribe().get(objectName);
            if (sot != null) {
                return sot.getDescribe().getLabel();
            }
            return objectName;
        } catch (Exception e) {
            return objectName;
        }
    }

    // Helper to get field label
    private static String getFieldLabel(String objectName, String fieldName) {
        try {
            // Field name comes as "ObjectName.FieldName"
            String actualFieldName = fieldName.contains('.') ? fieldName.substringAfter('.') : fieldName;
            Schema.SObjectType sot = getGlobalDescribe().get(objectName);
            if (sot != null) {
                Schema.SObjectField sof = sot.getDescribe().fields.getMap().get(actualFieldName);
                if (sof != null) {
                    return sof.getDescribe().getLabel();
                }
            }
            return actualFieldName;
        } catch (Exception e) {
            return fieldName;
        }
    }
}
