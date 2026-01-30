public with sharing class ProfileComparisonService {

    public static ProfileComparisonModels.ComparisonResult compareProfiles(
        ProfileComparisonModels.ProfileMetadata profile1,
        ProfileComparisonModels.ProfileMetadata profile2
    ) {
        ProfileComparisonModels.ComparisonResult result = new ProfileComparisonModels.ComparisonResult();
        result.profile1Name = profile1.profileName;
        result.profile2Name = profile2.profileName;

        result.assignedApps = compareApps(profile1.assignedApps, profile2.assignedApps);
        result.objectSettings = compareObjects(profile1.objectPermissions, profile2.objectPermissions);
        result.systemPermissions = compareSystemPermissions(profile1.systemPermissions, profile2.systemPermissions);
        result.apexClasses = compareEntityAccess(profile1.apexClassAccess, profile2.apexClassAccess);
        result.vfPages = compareEntityAccess(profile1.vfPageAccess, profile2.vfPageAccess);
        result.customPermissions = compareEntityAccess(profile1.customPermissions, profile2.customPermissions);

        result.summary = calculateSummary(result);

        return result;
    }

    private static List<ProfileComparisonModels.ComparisonRow> compareApps(
        List<ProfileComparisonModels.AppAccess> apps1,
        List<ProfileComparisonModels.AppAccess> apps2
    ) {
        List<ProfileComparisonModels.ComparisonRow> comparisons = new List<ProfileComparisonModels.ComparisonRow>();

        // Create maps keyed by app name
        Map<String, ProfileComparisonModels.AppAccess> map1 = new Map<String, ProfileComparisonModels.AppAccess>();
        Map<String, ProfileComparisonModels.AppAccess> map2 = new Map<String, ProfileComparisonModels.AppAccess>();

        if (apps1 != null) {
            for (ProfileComparisonModels.AppAccess app : apps1) {
                map1.put(app.appName, app);
            }
        }
        if (apps2 != null) {
            for (ProfileComparisonModels.AppAccess app : apps2) {
                map2.put(app.appName, app);
            }
        }

        // Get all unique app names
        Set<String> allApps = new Set<String>();
        allApps.addAll(map1.keySet());
        allApps.addAll(map2.keySet());

        for (String appName : allApps) {
            ProfileComparisonModels.AppAccess a1 = map1.get(appName);
            ProfileComparisonModels.AppAccess a2 = map2.get(appName);

            ProfileComparisonModels.ComparisonRow row = new ProfileComparisonModels.ComparisonRow();
            row.itemName = appName;
            row.itemLabel = a1 != null ? a1.appLabel : (a2 != null ? a2.appLabel : appName);

            String val1 = formatAppAccess(a1);
            String val2 = formatAppAccess(a2);

            row.profile1Value = val1;
            row.profile2Value = val2;
            row.isDifferent = val1 != val2;

            if (a1 != null && a2 == null) {
                row.diffType = 'ONLY_IN_P1';
            } else if (a1 == null && a2 != null) {
                row.diffType = 'ONLY_IN_P2';
            } else if (row.isDifferent) {
                row.diffType = 'CHANGED';
            } else {
                row.diffType = 'SAME';
            }

            comparisons.add(row);
        }

        comparisons.sort();
        return comparisons;
    }

    private static String formatAppAccess(ProfileComparisonModels.AppAccess app) {
        if (app == null) {
            return 'No Access';
        }
        String access = app.isVisible ? 'Visible' : 'Hidden';
        if (app.isDefault) {
            access += ' (Default)';
        }
        return access;
    }

    private static List<ProfileComparisonModels.ObjectComparisonRow> compareObjects(
        List<ProfileComparisonModels.ObjectPermission> objs1,
        List<ProfileComparisonModels.ObjectPermission> objs2
    ) {
        List<ProfileComparisonModels.ObjectComparisonRow> comparisons = new List<ProfileComparisonModels.ObjectComparisonRow>();

        // Create maps keyed by object name
        Map<String, ProfileComparisonModels.ObjectPermission> map1 = new Map<String, ProfileComparisonModels.ObjectPermission>();
        Map<String, ProfileComparisonModels.ObjectPermission> map2 = new Map<String, ProfileComparisonModels.ObjectPermission>();

        if (objs1 != null) {
            for (ProfileComparisonModels.ObjectPermission op : objs1) {
                map1.put(op.objectName, op);
            }
        }
        if (objs2 != null) {
            for (ProfileComparisonModels.ObjectPermission op : objs2) {
                map2.put(op.objectName, op);
            }
        }

        // Get all unique object names
        Set<String> allObjects = new Set<String>();
        allObjects.addAll(map1.keySet());
        allObjects.addAll(map2.keySet());

        List<String> sortedObjects = new List<String>(allObjects);
        sortedObjects.sort();

        for (String objName : sortedObjects) {
            ProfileComparisonModels.ObjectPermission op1 = map1.get(objName);
            ProfileComparisonModels.ObjectPermission op2 = map2.get(objName);

            ProfileComparisonModels.ObjectComparisonRow row = new ProfileComparisonModels.ObjectComparisonRow();
            row.objectName = objName;
            row.objectLabel = op1 != null ? op1.objectLabel : (op2 != null ? op2.objectLabel : objName);
            row.profile1Crud = formatCrud(op1);
            row.profile2Crud = formatCrud(op2);
            row.isDifferent = row.profile1Crud != row.profile2Crud;
            row.hasFLSDifferences = false;
            row.fieldComparisons = new List<ProfileComparisonModels.ComparisonRow>();

            comparisons.add(row);
        }

        return comparisons;
    }

    // Format CRUD as string like "CRED--" or "CR----"
    private static String formatCrud(ProfileComparisonModels.ObjectPermission op) {
        if (op == null) return '------';

        String crud = '';
        crud += op.canCreate ? 'C' : '-';
        crud += op.canRead ? 'R' : '-';
        crud += op.canEdit ? 'E' : '-';
        crud += op.canDelete ? 'D' : '-';
        crud += op.canViewAll ? 'V' : '-';
        crud += op.canModifyAll ? 'M' : '-';
        return crud;
    }

    private static List<ProfileComparisonModels.ComparisonRow> compareSystemPermissions(
        List<ProfileComparisonModels.SystemPermission> perms1,
        List<ProfileComparisonModels.SystemPermission> perms2
    ) {
        List<ProfileComparisonModels.ComparisonRow> comparisons = new List<ProfileComparisonModels.ComparisonRow>();

        // Create maps keyed by permission name
        Map<String, ProfileComparisonModels.SystemPermission> map1 = new Map<String, ProfileComparisonModels.SystemPermission>();
        Map<String, ProfileComparisonModels.SystemPermission> map2 = new Map<String, ProfileComparisonModels.SystemPermission>();

        if (perms1 != null) {
            for (ProfileComparisonModels.SystemPermission sp : perms1) {
                map1.put(sp.permissionName, sp);
            }
        }
        if (perms2 != null) {
            for (ProfileComparisonModels.SystemPermission sp : perms2) {
                map2.put(sp.permissionName, sp);
            }
        }

        // Get all unique permission names
        Set<String> allPerms = new Set<String>();
        allPerms.addAll(map1.keySet());
        allPerms.addAll(map2.keySet());

        for (String permName : allPerms) {
            ProfileComparisonModels.SystemPermission sp1 = map1.get(permName);
            ProfileComparisonModels.SystemPermission sp2 = map2.get(permName);

            ProfileComparisonModels.ComparisonRow row = new ProfileComparisonModels.ComparisonRow();
            row.itemName = permName;
            row.itemLabel = sp1 != null ? sp1.permissionLabel : (sp2 != null ? sp2.permissionLabel : permName);

            Boolean enabled1 = sp1 != null ? sp1.isEnabled : false;
            Boolean enabled2 = sp2 != null ? sp2.isEnabled : false;

            row.profile1Value = enabled1 ? 'Enabled' : 'Disabled';
            row.profile2Value = enabled2 ? 'Enabled' : 'Disabled';
            row.isDifferent = enabled1 != enabled2;

            if (row.isDifferent) {
                row.diffType = 'CHANGED';
            } else {
                row.diffType = 'SAME';
            }

            comparisons.add(row);
        }

        comparisons.sort();
        return comparisons;
    }

    private static List<ProfileComparisonModels.ComparisonRow> compareEntityAccess(
        List<ProfileComparisonModels.EntityAccess> access1,
        List<ProfileComparisonModels.EntityAccess> access2
    ) {
        List<ProfileComparisonModels.ComparisonRow> comparisons = new List<ProfileComparisonModels.ComparisonRow>();

        // Create sets of entity names that have access
        Set<String> set1 = new Set<String>();
        Set<String> set2 = new Set<String>();

        if (access1 != null) {
            for (ProfileComparisonModels.EntityAccess ea : access1) {
                set1.add(ea.entityName);
            }
        }
        if (access2 != null) {
            for (ProfileComparisonModels.EntityAccess ea : access2) {
                set2.add(ea.entityName);
            }
        }

        // Get all unique entities
        Set<String> allEntities = new Set<String>();
        allEntities.addAll(set1);
        allEntities.addAll(set2);

        List<String> sortedEntities = new List<String>(allEntities);
        sortedEntities.sort();

        for (String entityName : sortedEntities) {
            ProfileComparisonModels.ComparisonRow row = new ProfileComparisonModels.ComparisonRow();
            row.itemName = entityName;
            row.itemLabel = entityName;

            Boolean in1 = set1.contains(entityName);
            Boolean in2 = set2.contains(entityName);

            row.profile1Value = in1 ? 'Enabled' : 'Disabled';
            row.profile2Value = in2 ? 'Enabled' : 'Disabled';
            row.isDifferent = in1 != in2;

            if (in1 && !in2) {
                row.diffType = 'ONLY_IN_P1';
            } else if (!in1 && in2) {
                row.diffType = 'ONLY_IN_P2';
            } else {
                row.diffType = 'SAME';
            }

            comparisons.add(row);
        }

        return comparisons;
    }

    // Compare FLS for a specific object (called when expanding object row)
    public static List<ProfileComparisonModels.ComparisonRow> compareFieldPermissions(
        String permSetId1,
        String permSetId2,
        String objectName
    ) {
        List<ProfileComparisonModels.FieldPermission> fls1 = ProfileMetadataService.getFieldPermissions(permSetId1, objectName);
        List<ProfileComparisonModels.FieldPermission> fls2 = ProfileMetadataService.getFieldPermissions(permSetId2, objectName);

        // Create maps and compare
        Map<String, ProfileComparisonModels.FieldPermission> map1 = new Map<String, ProfileComparisonModels.FieldPermission>();
        Map<String, ProfileComparisonModels.FieldPermission> map2 = new Map<String, ProfileComparisonModels.FieldPermission>();

        for (ProfileComparisonModels.FieldPermission fp : fls1) {
            map1.put(fp.fieldName, fp);
        }
        for (ProfileComparisonModels.FieldPermission fp : fls2) {
            map2.put(fp.fieldName, fp);
        }

        Set<String> allFields = new Set<String>();
        allFields.addAll(map1.keySet());
        allFields.addAll(map2.keySet());

        List<String> sortedFields = new List<String>(allFields);
        sortedFields.sort();

        List<ProfileComparisonModels.ComparisonRow> comparisons = new List<ProfileComparisonModels.ComparisonRow>();

        for (String fieldName : sortedFields) {
            ProfileComparisonModels.FieldPermission fp1 = map1.get(fieldName);
            ProfileComparisonModels.FieldPermission fp2 = map2.get(fieldName);

            ProfileComparisonModels.ComparisonRow row = new ProfileComparisonModels.ComparisonRow();
            row.itemName = fieldName;
            row.itemLabel = fp1 != null ? fp1.fieldLabel : (fp2 != null ? fp2.fieldLabel : fieldName);
            row.profile1Value = formatFls(fp1);
            row.profile2Value = formatFls(fp2);
            row.isDifferent = row.profile1Value != row.profile2Value;

            if (row.isDifferent) {
                row.diffType = 'CHANGED';
            } else {
                row.diffType = 'SAME';
            }

            comparisons.add(row);
        }

        return comparisons;
    }

    // Format FLS as "Read/Write", "Read Only", "No Access"
    private static String formatFls(ProfileComparisonModels.FieldPermission fp) {
        if (fp == null) return 'No Access';
        if (fp.canRead && fp.canEdit) return 'Read/Write';
        if (fp.canRead) return 'Read Only';
        return 'No Access';
    }

    private static ProfileComparisonModels.ComparisonSummary calculateSummary(ProfileComparisonModels.ComparisonResult result) {
        ProfileComparisonModels.ComparisonSummary summary = new ProfileComparisonModels.ComparisonSummary();

        summary.totalApps = result.assignedApps != null ? result.assignedApps.size() : 0;
        summary.differentApps = countDifferences(result.assignedApps);

        summary.totalObjects = result.objectSettings != null ? result.objectSettings.size() : 0;
        summary.differentObjects = 0;
        if (result.objectSettings != null) {
            for (ProfileComparisonModels.ObjectComparisonRow obj : result.objectSettings) {
                if (obj.isDifferent) {
                    summary.differentObjects++;
                }
            }
        }

        summary.totalSystemPerms = result.systemPermissions != null ? result.systemPermissions.size() : 0;
        summary.differentSystemPerms = countDifferences(result.systemPermissions);

        summary.totalApexClasses = result.apexClasses != null ? result.apexClasses.size() : 0;
        summary.differentApexClasses = countDifferences(result.apexClasses);

        summary.totalVfPages = result.vfPages != null ? result.vfPages.size() : 0;
        summary.differentVfPages = countDifferences(result.vfPages);

        summary.totalCustomPerms = result.customPermissions != null ? result.customPermissions.size() : 0;
        summary.differentCustomPerms = countDifferences(result.customPermissions);

        return summary;
    }

    private static Integer countDifferences(List<ProfileComparisonModels.ComparisonRow> rows) {
        Integer count = 0;
        if (rows != null) {
            for (ProfileComparisonModels.ComparisonRow row : rows) {
                if (row.isDifferent) {
                    count++;
                }
            }
        }
        return count;
    }
}
