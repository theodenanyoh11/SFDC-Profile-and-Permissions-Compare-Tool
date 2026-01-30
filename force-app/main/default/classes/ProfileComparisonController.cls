public with sharing class ProfileComparisonController {

    @AuraEnabled(cacheable=true)
    public static List<ProfileComparisonModels.ProfileInfo> getProfiles() {
        return ProfileMetadataService.getAllProfiles();
    }

    @AuraEnabled
    public static ProfileComparisonModels.ComparisonResult compareProfiles(String profileId1, String profileId2) {
        ProfileComparisonModels.ProfileMetadata profile1 = ProfileMetadataService.getProfileMetadata(profileId1);
        ProfileComparisonModels.ProfileMetadata profile2 = ProfileMetadataService.getProfileMetadata(profileId2);

        return ProfileComparisonService.compareProfiles(profile1, profile2);
    }

    @AuraEnabled
    public static List<ProfileComparisonModels.ComparisonRow> getFieldComparison(
        String profileId1,
        String profileId2,
        String objectName
    ) {
        String permSetId1 = ProfileMetadataService.getPermissionSetIdForProfile(profileId1);
        String permSetId2 = ProfileMetadataService.getPermissionSetIdForProfile(profileId2);

        return ProfileComparisonService.compareFieldPermissions(permSetId1, permSetId2, objectName);
    }
}
