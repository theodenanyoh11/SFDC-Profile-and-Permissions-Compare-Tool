@IsTest
private class ProfileComparisonController_Test {

    @IsTest
    static void testGetProfiles() {
        List<ProfileComparisonModels.ProfileInfo> profiles = ProfileComparisonController.getProfiles();

        System.assertNotEquals(null, profiles, 'Profiles list should not be null');
        System.assert(!profiles.isEmpty(), 'There should be at least one profile in the org');

        // Verify the System Administrator profile exists
        Boolean hasAdmin = false;
        for (ProfileComparisonModels.ProfileInfo pi : profiles) {
            System.assertNotEquals(null, pi.profileId, 'Profile Id should not be null');
            System.assertNotEquals(null, pi.profileName, 'Profile Name should not be null');
            if (pi.profileName == 'System Administrator') {
                hasAdmin = true;
            }
        }
        System.assert(hasAdmin, 'System Administrator profile should exist');
    }

    @IsTest
    static void testCompareProfiles() {
        // Get two profiles to compare
        List<Profile> profiles = [SELECT Id FROM Profile ORDER BY Name LIMIT 2];
        System.assert(profiles.size() >= 2, 'Need at least 2 profiles to test comparison');

        Test.startTest();
        ProfileComparisonModels.ComparisonResult result = ProfileComparisonController.compareProfiles(
            profiles[0].Id,
            profiles[1].Id
        );
        Test.stopTest();

        System.assertNotEquals(null, result, 'Comparison result should not be null');
        System.assertNotEquals(null, result.profile1Name, 'Profile 1 name should not be null');
        System.assertNotEquals(null, result.profile2Name, 'Profile 2 name should not be null');
        System.assertNotEquals(null, result.summary, 'Summary should not be null');
        System.assertNotEquals(null, result.assignedApps, 'Assigned apps should not be null');
        System.assertNotEquals(null, result.objectSettings, 'Object settings should not be null');
        System.assertNotEquals(null, result.systemPermissions, 'System permissions should not be null');
        System.assertNotEquals(null, result.apexClasses, 'Apex classes should not be null');
        System.assertNotEquals(null, result.vfPages, 'VF pages should not be null');
        System.assertNotEquals(null, result.customPermissions, 'Custom permissions should not be null');
    }

    @IsTest
    static void testCompareSameProfile() {
        Profile p = [SELECT Id FROM Profile WHERE Name = 'System Administrator' LIMIT 1];

        Test.startTest();
        ProfileComparisonModels.ComparisonResult result = ProfileComparisonController.compareProfiles(
            p.Id,
            p.Id
        );
        Test.stopTest();

        System.assertNotEquals(null, result, 'Result should not be null');
        // When comparing same profile, there should be no differences in object settings
        for (ProfileComparisonModels.ObjectComparisonRow obj : result.objectSettings) {
            System.assertEquals(false, obj.isDifferent, 'Same profile should have no CRUD differences for ' + obj.objectName);
        }
        // System permissions should also be identical
        for (ProfileComparisonModels.ComparisonRow row : result.systemPermissions) {
            System.assertEquals(false, row.isDifferent, 'Same profile should have no system perm differences for ' + row.itemName);
        }
    }

    @IsTest
    static void testGetFieldComparison() {
        List<Profile> profiles = [SELECT Id FROM Profile ORDER BY Name LIMIT 2];
        System.assert(profiles.size() >= 2, 'Need at least 2 profiles');

        // Find an object that has object permissions for the first profile
        String permSetId = ProfileMetadataService.getPermissionSetIdForProfile(profiles[0].Id);
        List<ObjectPermissions> ops = [
            SELECT SobjectType
            FROM ObjectPermissions
            WHERE ParentId = :permSetId
            LIMIT 1
        ];

        if (!ops.isEmpty()) {
            Test.startTest();
            List<ProfileComparisonModels.ComparisonRow> fieldComparisons =
                ProfileComparisonController.getFieldComparison(
                    profiles[0].Id,
                    profiles[1].Id,
                    ops[0].SobjectType
                );
            Test.stopTest();

            System.assertNotEquals(null, fieldComparisons, 'Field comparisons should not be null');
        }
    }

    @IsTest
    static void testComparisonSummaryCalculation() {
        List<Profile> profiles = [SELECT Id FROM Profile ORDER BY Name LIMIT 2];
        System.assert(profiles.size() >= 2, 'Need at least 2 profiles');

        Test.startTest();
        ProfileComparisonModels.ComparisonResult result = ProfileComparisonController.compareProfiles(
            profiles[0].Id,
            profiles[1].Id
        );
        Test.stopTest();

        ProfileComparisonModels.ComparisonSummary summary = result.summary;
        System.assertNotEquals(null, summary, 'Summary should not be null');

        // Total counts should be >= difference counts
        System.assert(summary.totalApps >= summary.differentApps, 'Total apps should be >= different apps');
        System.assert(summary.totalObjects >= summary.differentObjects, 'Total objects should be >= different objects');
        System.assert(summary.totalSystemPerms >= summary.differentSystemPerms, 'Total system perms should be >= different system perms');
        System.assert(summary.totalApexClasses >= summary.differentApexClasses, 'Total apex classes should be >= different apex classes');
        System.assert(summary.totalVfPages >= summary.differentVfPages, 'Total VF pages should be >= different VF pages');
        System.assert(summary.totalCustomPerms >= summary.differentCustomPerms, 'Total custom perms should be >= different custom perms');
    }
}
