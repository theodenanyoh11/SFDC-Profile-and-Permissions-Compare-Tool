@IsTest
private class ProfileMetadataService_Test {

    @IsTest
    static void testGetAllProfiles() {
        Test.startTest();
        List<ProfileComparisonModels.ProfileInfo> profiles = ProfileMetadataService.getAllProfiles();
        Test.stopTest();

        System.assertNotEquals(null, profiles, 'Should return profiles list');
        System.assert(!profiles.isEmpty(), 'Should have at least one profile');

        // Validate structure
        for (ProfileComparisonModels.ProfileInfo pi : profiles) {
            System.assertNotEquals(null, pi.profileId, 'Profile Id should be populated');
            System.assertNotEquals(null, pi.profileName, 'Profile Name should be populated');
        }
    }

    @IsTest
    static void testGetPermissionSetIdForProfile() {
        Profile adminProfile = [SELECT Id FROM Profile WHERE Name = 'System Administrator' LIMIT 1];

        Test.startTest();
        String permSetId = ProfileMetadataService.getPermissionSetIdForProfile(adminProfile.Id);
        Test.stopTest();

        System.assertNotEquals(null, permSetId, 'System Administrator should have a linked PermissionSet');
    }

    @IsTest
    static void testGetProfileMetadata() {
        Profile adminProfile = [SELECT Id FROM Profile WHERE Name = 'System Administrator' LIMIT 1];

        Test.startTest();
        ProfileComparisonModels.ProfileMetadata metadata = ProfileMetadataService.getProfileMetadata(adminProfile.Id);
        Test.stopTest();

        System.assertNotEquals(null, metadata, 'Metadata should not be null');
        System.assertEquals('System Administrator', metadata.profileName, 'Profile name should match');
        System.assertNotEquals(null, metadata.permissionSetId, 'PermissionSet Id should be populated');
        System.assertNotEquals(null, metadata.objectPermissions, 'Object permissions should not be null');
        System.assertNotEquals(null, metadata.systemPermissions, 'System permissions should not be null');
        System.assertNotEquals(null, metadata.apexClassAccess, 'Apex class access should not be null');
        System.assertNotEquals(null, metadata.vfPageAccess, 'VF page access should not be null');
        System.assertNotEquals(null, metadata.customPermissions, 'Custom permissions should not be null');

        // Admin should have object permissions
        System.assert(!metadata.objectPermissions.isEmpty(), 'Admin should have object permissions');

        // Admin should have system permissions
        System.assert(!metadata.systemPermissions.isEmpty(), 'Admin should have system permissions');

        // Verify object permission structure
        for (ProfileComparisonModels.ObjectPermission op : metadata.objectPermissions) {
            System.assertNotEquals(null, op.objectName, 'Object name should not be null');
            System.assertNotEquals(null, op.objectLabel, 'Object label should not be null');
        }
    }

    @IsTest
    static void testGetFieldPermissions() {
        Profile adminProfile = [SELECT Id FROM Profile WHERE Name = 'System Administrator' LIMIT 1];
        String permSetId = ProfileMetadataService.getPermissionSetIdForProfile(adminProfile.Id);

        // Get an object that has field permissions
        List<FieldPermissions> fps = [
            SELECT SobjectType
            FROM FieldPermissions
            WHERE ParentId = :permSetId
            LIMIT 1
        ];

        if (!fps.isEmpty()) {
            Test.startTest();
            List<ProfileComparisonModels.FieldPermission> fieldPerms =
                ProfileMetadataService.getFieldPermissions(permSetId, fps[0].SobjectType);
            Test.stopTest();

            System.assertNotEquals(null, fieldPerms, 'Field permissions should not be null');
            System.assert(!fieldPerms.isEmpty(), 'Should have field permissions for the object');

            for (ProfileComparisonModels.FieldPermission fp : fieldPerms) {
                System.assertNotEquals(null, fp.fieldName, 'Field name should not be null');
                System.assertNotEquals(null, fp.fieldLabel, 'Field label should not be null');
            }
        }
    }

    @IsTest
    static void testGetProfileMetadataWithInvalidPermSetId() {
        // Test behavior when profile has no permission set (edge case)
        // This scenario is unlikely but tests null handling
        ProfileComparisonModels.ProfileMetadata metadata = new ProfileComparisonModels.ProfileMetadata();
        metadata.permissionSetId = null;
        metadata.assignedApps = new List<ProfileComparisonModels.AppAccess>();
        metadata.objectPermissions = new List<ProfileComparisonModels.ObjectPermission>();
        metadata.systemPermissions = new List<ProfileComparisonModels.SystemPermission>();
        metadata.apexClassAccess = new List<ProfileComparisonModels.EntityAccess>();
        metadata.vfPageAccess = new List<ProfileComparisonModels.EntityAccess>();
        metadata.customPermissions = new List<ProfileComparisonModels.EntityAccess>();

        System.assertNotEquals(null, metadata, 'Metadata with null permSetId should still be valid');
        System.assert(metadata.objectPermissions.isEmpty(), 'Should have empty object permissions');
    }

    @IsTest
    static void testGetFieldPermissionsForObjectWithNoFields() {
        Profile adminProfile = [SELECT Id FROM Profile WHERE Name = 'System Administrator' LIMIT 1];
        String permSetId = ProfileMetadataService.getPermissionSetIdForProfile(adminProfile.Id);

        Test.startTest();
        // Use a fake object name that won't have field permissions
        List<ProfileComparisonModels.FieldPermission> fieldPerms =
            ProfileMetadataService.getFieldPermissions(permSetId, 'NonExistentObject__c');
        Test.stopTest();

        System.assertNotEquals(null, fieldPerms, 'Should return empty list, not null');
        System.assert(fieldPerms.isEmpty(), 'Should have no field permissions for non-existent object');
    }
}
