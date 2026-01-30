@IsTest
private class ProfileComparisonService_Test {

    @IsTest
    static void testCompareProfilesWithRealData() {
        List<Profile> profiles = [SELECT Id, Name FROM Profile ORDER BY Name LIMIT 2];
        System.assert(profiles.size() >= 2, 'Need at least 2 profiles');

        ProfileComparisonModels.ProfileMetadata metadata1 = ProfileMetadataService.getProfileMetadata(profiles[0].Id);
        ProfileComparisonModels.ProfileMetadata metadata2 = ProfileMetadataService.getProfileMetadata(profiles[1].Id);

        Test.startTest();
        ProfileComparisonModels.ComparisonResult result = ProfileComparisonService.compareProfiles(metadata1, metadata2);
        Test.stopTest();

        System.assertNotEquals(null, result, 'Result should not be null');
        System.assertEquals(metadata1.profileName, result.profile1Name, 'Profile 1 name should match');
        System.assertEquals(metadata2.profileName, result.profile2Name, 'Profile 2 name should match');
    }

    @IsTest
    static void testCompareEmptyProfiles() {
        // Test with empty metadata (edge case)
        ProfileComparisonModels.ProfileMetadata empty1 = createEmptyMetadata('Empty Profile 1');
        ProfileComparisonModels.ProfileMetadata empty2 = createEmptyMetadata('Empty Profile 2');

        Test.startTest();
        ProfileComparisonModels.ComparisonResult result = ProfileComparisonService.compareProfiles(empty1, empty2);
        Test.stopTest();

        System.assertNotEquals(null, result, 'Result should not be null');
        System.assertEquals(0, result.summary.totalObjects, 'Should have 0 objects');
        System.assertEquals(0, result.summary.differentObjects, 'Should have 0 object differences');
        System.assertEquals(0, result.summary.totalApps, 'Should have 0 apps');
        System.assertEquals(0, result.summary.differentApps, 'Should have 0 app differences');
    }

    @IsTest
    static void testCompareObjectPermissions() {
        // Create mock object permissions
        ProfileComparisonModels.ProfileMetadata meta1 = createEmptyMetadata('Profile A');
        ProfileComparisonModels.ProfileMetadata meta2 = createEmptyMetadata('Profile B');

        ProfileComparisonModels.ObjectPermission op1 = new ProfileComparisonModels.ObjectPermission();
        op1.objectName = 'Account';
        op1.objectLabel = 'Account';
        op1.canCreate = true;
        op1.canRead = true;
        op1.canEdit = true;
        op1.canDelete = true;
        op1.canViewAll = false;
        op1.canModifyAll = false;
        op1.fieldPermissions = new List<ProfileComparisonModels.FieldPermission>();

        ProfileComparisonModels.ObjectPermission op2 = new ProfileComparisonModels.ObjectPermission();
        op2.objectName = 'Account';
        op2.objectLabel = 'Account';
        op2.canCreate = true;
        op2.canRead = true;
        op2.canEdit = false;
        op2.canDelete = false;
        op2.canViewAll = false;
        op2.canModifyAll = false;
        op2.fieldPermissions = new List<ProfileComparisonModels.FieldPermission>();

        meta1.objectPermissions.add(op1);
        meta2.objectPermissions.add(op2);

        Test.startTest();
        ProfileComparisonModels.ComparisonResult result = ProfileComparisonService.compareProfiles(meta1, meta2);
        Test.stopTest();

        System.assertEquals(1, result.objectSettings.size(), 'Should have 1 object comparison');
        ProfileComparisonModels.ObjectComparisonRow objRow = result.objectSettings[0];
        System.assertEquals('Account', objRow.objectName, 'Object name should be Account');
        System.assertEquals(true, objRow.isDifferent, 'CRUD should be different');
        System.assertEquals('CRED--', objRow.profile1Crud, 'Profile 1 should have CRED--');
        System.assertEquals('CR----', objRow.profile2Crud, 'Profile 2 should have CR----');
    }

    @IsTest
    static void testCompareObjectPermissionsOnlyInOneProfile() {
        ProfileComparisonModels.ProfileMetadata meta1 = createEmptyMetadata('Profile A');
        ProfileComparisonModels.ProfileMetadata meta2 = createEmptyMetadata('Profile B');

        ProfileComparisonModels.ObjectPermission op1 = new ProfileComparisonModels.ObjectPermission();
        op1.objectName = 'Contact';
        op1.objectLabel = 'Contact';
        op1.canCreate = true;
        op1.canRead = true;
        op1.canEdit = true;
        op1.canDelete = false;
        op1.canViewAll = false;
        op1.canModifyAll = false;
        op1.fieldPermissions = new List<ProfileComparisonModels.FieldPermission>();

        meta1.objectPermissions.add(op1);
        // meta2 has no Contact permission

        Test.startTest();
        ProfileComparisonModels.ComparisonResult result = ProfileComparisonService.compareProfiles(meta1, meta2);
        Test.stopTest();

        System.assertEquals(1, result.objectSettings.size(), 'Should have 1 object comparison');
        ProfileComparisonModels.ObjectComparisonRow objRow = result.objectSettings[0];
        System.assertEquals(true, objRow.isDifferent, 'Should be different when only in one profile');
        System.assertEquals('CRE---', objRow.profile1Crud, 'Profile 1 should have CRE---');
        System.assertEquals('------', objRow.profile2Crud, 'Profile 2 should have ------');
    }

    @IsTest
    static void testCompareEntityAccess() {
        ProfileComparisonModels.ProfileMetadata meta1 = createEmptyMetadata('Profile A');
        ProfileComparisonModels.ProfileMetadata meta2 = createEmptyMetadata('Profile B');

        // Both have MyClass access
        ProfileComparisonModels.EntityAccess ea1 = new ProfileComparisonModels.EntityAccess();
        ea1.entityName = 'MyApexClass';
        ea1.entityId = '01p000000000001';
        ea1.hasAccess = true;
        meta1.apexClassAccess.add(ea1);

        ProfileComparisonModels.EntityAccess ea2 = new ProfileComparisonModels.EntityAccess();
        ea2.entityName = 'MyApexClass';
        ea2.entityId = '01p000000000001';
        ea2.hasAccess = true;
        meta2.apexClassAccess.add(ea2);

        // Only profile 1 has AnotherClass
        ProfileComparisonModels.EntityAccess ea3 = new ProfileComparisonModels.EntityAccess();
        ea3.entityName = 'AnotherClass';
        ea3.entityId = '01p000000000002';
        ea3.hasAccess = true;
        meta1.apexClassAccess.add(ea3);

        Test.startTest();
        ProfileComparisonModels.ComparisonResult result = ProfileComparisonService.compareProfiles(meta1, meta2);
        Test.stopTest();

        System.assertEquals(2, result.apexClasses.size(), 'Should have 2 apex class comparisons');

        // Find AnotherClass row
        ProfileComparisonModels.ComparisonRow anotherClassRow;
        ProfileComparisonModels.ComparisonRow myClassRow;
        for (ProfileComparisonModels.ComparisonRow row : result.apexClasses) {
            if (row.itemName == 'AnotherClass') {
                anotherClassRow = row;
            } else if (row.itemName == 'MyApexClass') {
                myClassRow = row;
            }
        }

        System.assertNotEquals(null, anotherClassRow, 'AnotherClass row should exist');
        System.assertEquals(true, anotherClassRow.isDifferent, 'AnotherClass should show as different');
        System.assertEquals('Enabled', anotherClassRow.profile1Value, 'Profile 1 should have Enabled');
        System.assertEquals('Disabled', anotherClassRow.profile2Value, 'Profile 2 should have Disabled');
        System.assertEquals('ONLY_IN_P1', anotherClassRow.diffType, 'Should be ONLY_IN_P1');

        System.assertNotEquals(null, myClassRow, 'MyApexClass row should exist');
        System.assertEquals(false, myClassRow.isDifferent, 'MyApexClass should not show as different');
        System.assertEquals('SAME', myClassRow.diffType, 'Should be SAME');
    }

    @IsTest
    static void testCompareSystemPermissions() {
        ProfileComparisonModels.ProfileMetadata meta1 = createEmptyMetadata('Profile A');
        ProfileComparisonModels.ProfileMetadata meta2 = createEmptyMetadata('Profile B');

        ProfileComparisonModels.SystemPermission sp1 = new ProfileComparisonModels.SystemPermission();
        sp1.permissionName = 'ApiEnabled';
        sp1.permissionLabel = 'API Enabled';
        sp1.isEnabled = true;
        meta1.systemPermissions.add(sp1);

        ProfileComparisonModels.SystemPermission sp2 = new ProfileComparisonModels.SystemPermission();
        sp2.permissionName = 'ApiEnabled';
        sp2.permissionLabel = 'API Enabled';
        sp2.isEnabled = false;
        meta2.systemPermissions.add(sp2);

        Test.startTest();
        ProfileComparisonModels.ComparisonResult result = ProfileComparisonService.compareProfiles(meta1, meta2);
        Test.stopTest();

        System.assertEquals(1, result.systemPermissions.size(), 'Should have 1 system permission comparison');
        ProfileComparisonModels.ComparisonRow row = result.systemPermissions[0];
        System.assertEquals(true, row.isDifferent, 'Should be different');
        System.assertEquals('Enabled', row.profile1Value, 'Profile 1 should be Enabled');
        System.assertEquals('Disabled', row.profile2Value, 'Profile 2 should be Disabled');
    }

    @IsTest
    static void testCompareFieldPermissions() {
        Profile adminProfile = [SELECT Id FROM Profile WHERE Name = 'System Administrator' LIMIT 1];
        String permSetId = ProfileMetadataService.getPermissionSetIdForProfile(adminProfile.Id);

        // Get a standard profile to compare against
        List<Profile> otherProfiles = [
            SELECT Id FROM Profile
            WHERE Name != 'System Administrator'
            ORDER BY Name LIMIT 1
        ];

        if (!otherProfiles.isEmpty()) {
            String permSetId2 = ProfileMetadataService.getPermissionSetIdForProfile(otherProfiles[0].Id);

            // Find an object that has field permissions
            List<FieldPermissions> fps = [
                SELECT SobjectType
                FROM FieldPermissions
                WHERE ParentId = :permSetId
                LIMIT 1
            ];

            if (!fps.isEmpty() && permSetId2 != null) {
                Test.startTest();
                List<ProfileComparisonModels.ComparisonRow> fieldComparisons =
                    ProfileComparisonService.compareFieldPermissions(permSetId, permSetId2, fps[0].SobjectType);
                Test.stopTest();

                System.assertNotEquals(null, fieldComparisons, 'Field comparisons should not be null');
            }
        }
    }

    @IsTest
    static void testCompareApps() {
        ProfileComparisonModels.ProfileMetadata meta1 = createEmptyMetadata('Profile A');
        ProfileComparisonModels.ProfileMetadata meta2 = createEmptyMetadata('Profile B');

        ProfileComparisonModels.AppAccess app1 = new ProfileComparisonModels.AppAccess();
        app1.appName = 'Sales';
        app1.appLabel = 'Sales';
        app1.isVisible = true;
        app1.isDefault = true;
        meta1.assignedApps.add(app1);

        ProfileComparisonModels.AppAccess app2 = new ProfileComparisonModels.AppAccess();
        app2.appName = 'Sales';
        app2.appLabel = 'Sales';
        app2.isVisible = true;
        app2.isDefault = false;
        meta2.assignedApps.add(app2);

        Test.startTest();
        ProfileComparisonModels.ComparisonResult result = ProfileComparisonService.compareProfiles(meta1, meta2);
        Test.stopTest();

        System.assertEquals(1, result.assignedApps.size(), 'Should have 1 app comparison');
        ProfileComparisonModels.ComparisonRow row = result.assignedApps[0];
        System.assertEquals(true, row.isDifferent, 'Apps should be different (default vs non-default)');
    }

    @IsTest
    static void testSummaryCounts() {
        ProfileComparisonModels.ProfileMetadata meta1 = createEmptyMetadata('Profile A');
        ProfileComparisonModels.ProfileMetadata meta2 = createEmptyMetadata('Profile B');

        // Add some differences
        addObjectPermission(meta1, 'Account', true, true, true, true, false, false);
        addObjectPermission(meta2, 'Account', true, true, false, false, false, false);
        addObjectPermission(meta1, 'Contact', true, true, true, false, false, false);
        addObjectPermission(meta2, 'Contact', true, true, true, false, false, false);

        Test.startTest();
        ProfileComparisonModels.ComparisonResult result = ProfileComparisonService.compareProfiles(meta1, meta2);
        Test.stopTest();

        System.assertEquals(2, result.summary.totalObjects, 'Should have 2 total objects');
        System.assertEquals(1, result.summary.differentObjects, 'Should have 1 different object');
    }

    // Helper methods
    private static ProfileComparisonModels.ProfileMetadata createEmptyMetadata(String name) {
        ProfileComparisonModels.ProfileMetadata metadata = new ProfileComparisonModels.ProfileMetadata();
        metadata.profileId = '00e000000000000';
        metadata.profileName = name;
        metadata.permissionSetId = '0PS000000000000';
        metadata.assignedApps = new List<ProfileComparisonModels.AppAccess>();
        metadata.objectPermissions = new List<ProfileComparisonModels.ObjectPermission>();
        metadata.systemPermissions = new List<ProfileComparisonModels.SystemPermission>();
        metadata.apexClassAccess = new List<ProfileComparisonModels.EntityAccess>();
        metadata.vfPageAccess = new List<ProfileComparisonModels.EntityAccess>();
        metadata.customPermissions = new List<ProfileComparisonModels.EntityAccess>();
        return metadata;
    }

    private static void addObjectPermission(
        ProfileComparisonModels.ProfileMetadata metadata,
        String objectName,
        Boolean canCreate,
        Boolean canRead,
        Boolean canEdit,
        Boolean canDelete,
        Boolean canViewAll,
        Boolean canModifyAll
    ) {
        ProfileComparisonModels.ObjectPermission op = new ProfileComparisonModels.ObjectPermission();
        op.objectName = objectName;
        op.objectLabel = objectName;
        op.canCreate = canCreate;
        op.canRead = canRead;
        op.canEdit = canEdit;
        op.canDelete = canDelete;
        op.canViewAll = canViewAll;
        op.canModifyAll = canModifyAll;
        op.fieldPermissions = new List<ProfileComparisonModels.FieldPermission>();
        metadata.objectPermissions.add(op);
    }
}
