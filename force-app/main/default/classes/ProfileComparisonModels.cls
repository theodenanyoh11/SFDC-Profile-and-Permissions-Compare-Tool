public class ProfileComparisonModels {

    // Wrapper for app access
    public class AppAccess {
        @AuraEnabled public String appName;
        @AuraEnabled public String appLabel;
        @AuraEnabled public Boolean isVisible;
        @AuraEnabled public Boolean isDefault;
    }

    // Wrapper for field permissions
    public class FieldPermission {
        @AuraEnabled public String fieldName;
        @AuraEnabled public String fieldLabel;
        @AuraEnabled public Boolean canRead;
        @AuraEnabled public Boolean canEdit;
    }

    // Wrapper for object permissions
    public class ObjectPermission {
        @AuraEnabled public String objectName;
        @AuraEnabled public String objectLabel;
        @AuraEnabled public Boolean canCreate;
        @AuraEnabled public Boolean canRead;
        @AuraEnabled public Boolean canEdit;
        @AuraEnabled public Boolean canDelete;
        @AuraEnabled public Boolean canViewAll;
        @AuraEnabled public Boolean canModifyAll;
        @AuraEnabled public List<FieldPermission> fieldPermissions;
    }

    // Wrapper for system/app permissions
    public class SystemPermission implements Comparable {
        @AuraEnabled public String permissionName;
        @AuraEnabled public String permissionLabel;
        @AuraEnabled public Boolean isEnabled;

        public Integer compareTo(Object compareTo) {
            SystemPermission other = (SystemPermission) compareTo;
            if (this.permissionLabel == null && other.permissionLabel == null) return 0;
            if (this.permissionLabel == null) return -1;
            if (other.permissionLabel == null) return 1;
            return this.permissionLabel.compareTo(other.permissionLabel);
        }
    }

    // Wrapper for setup entity access (Apex, VF, Custom Perms)
    public class EntityAccess {
        @AuraEnabled public String entityName;
        @AuraEnabled public String entityId;
        @AuraEnabled public Boolean hasAccess;
    }

    // Complete profile metadata
    public class ProfileMetadata {
        @AuraEnabled public String profileId;
        @AuraEnabled public String profileName;
        @AuraEnabled public String permissionSetId;
        @AuraEnabled public List<AppAccess> assignedApps;
        @AuraEnabled public List<ObjectPermission> objectPermissions;
        @AuraEnabled public List<SystemPermission> systemPermissions;
        @AuraEnabled public List<EntityAccess> apexClassAccess;
        @AuraEnabled public List<EntityAccess> vfPageAccess;
        @AuraEnabled public List<EntityAccess> customPermissions;
    }

    // Generic comparison row for most categories
    public class ComparisonRow implements Comparable {
        @AuraEnabled public String itemName;
        @AuraEnabled public String itemLabel;
        @AuraEnabled public String profile1Value;
        @AuraEnabled public String profile2Value;
        @AuraEnabled public Boolean isDifferent;
        @AuraEnabled public String diffType; // 'SAME', 'CHANGED', 'ONLY_IN_P1', 'ONLY_IN_P2'

        public Integer compareTo(Object compareTo) {
            ComparisonRow other = (ComparisonRow) compareTo;
            if (this.itemLabel == null && other.itemLabel == null) return 0;
            if (this.itemLabel == null) return -1;
            if (other.itemLabel == null) return 1;
            return this.itemLabel.compareTo(other.itemLabel);
        }
    }

    // Specialized comparison row for objects (includes FLS)
    public class ObjectComparisonRow {
        @AuraEnabled public String objectName;
        @AuraEnabled public String objectLabel;
        @AuraEnabled public String profile1Crud;
        @AuraEnabled public String profile2Crud;
        @AuraEnabled public Boolean isDifferent;
        @AuraEnabled public Boolean hasFLSDifferences;
        @AuraEnabled public List<ComparisonRow> fieldComparisons;
    }

    // Complete comparison result
    public class ComparisonResult {
        @AuraEnabled public String profile1Name;
        @AuraEnabled public String profile2Name;
        @AuraEnabled public List<ComparisonRow> assignedApps;
        @AuraEnabled public List<ObjectComparisonRow> objectSettings;
        @AuraEnabled public List<ComparisonRow> systemPermissions;
        @AuraEnabled public List<ComparisonRow> apexClasses;
        @AuraEnabled public List<ComparisonRow> vfPages;
        @AuraEnabled public List<ComparisonRow> customPermissions;
        @AuraEnabled public ComparisonSummary summary;
    }

    // Summary statistics
    public class ComparisonSummary {
        @AuraEnabled public Integer totalApps;
        @AuraEnabled public Integer differentApps;
        @AuraEnabled public Integer totalObjects;
        @AuraEnabled public Integer differentObjects;
        @AuraEnabled public Integer totalSystemPerms;
        @AuraEnabled public Integer differentSystemPerms;
        @AuraEnabled public Integer totalApexClasses;
        @AuraEnabled public Integer differentApexClasses;
        @AuraEnabled public Integer totalVfPages;
        @AuraEnabled public Integer differentVfPages;
        @AuraEnabled public Integer totalCustomPerms;
        @AuraEnabled public Integer differentCustomPerms;
    }

    // Simple profile info for dropdowns
    public class ProfileInfo {
        @AuraEnabled public String profileId;
        @AuraEnabled public String profileName;
        @AuraEnabled public String userLicenseName;
    }
}
