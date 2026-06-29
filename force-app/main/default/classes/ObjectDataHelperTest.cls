@isTest
private class ObjectDataHelperTest {

    // ── SObjectWrapper ────────────────────────────────────────────────────────

    @isTest
    static void testSObjectWrapper_constructorSetsProperties() {
        ObjectDataHelper.SObjectWrapper wrapper =
            new ObjectDataHelper.SObjectWrapper('Contact', 'Contact');

        Assert.areEqual('Contact', wrapper.apiName);
        Assert.areEqual('Contact', wrapper.label);
    }

    @isTest
    static void testSObjectWrapper_compareToSortsByLabel() {
        ObjectDataHelper.SObjectWrapper alpha = new ObjectDataHelper.SObjectWrapper('Account', 'Account');
        ObjectDataHelper.SObjectWrapper zeta  = new ObjectDataHelper.SObjectWrapper('ZObject', 'ZObject');

        Assert.isTrue(alpha.compareTo(zeta) < 0,  'Account should sort before ZObject');
        Assert.isTrue(zeta.compareTo(alpha) > 0,  'ZObject should sort after Account');
        Assert.areEqual(0, alpha.compareTo(alpha), 'Same label should return 0');
    }

    // ── getNonSetupObjects ────────────────────────────────────────────────────

    @isTest
    static void testGetNonSetupObjects_returnsNonEmptyList() {
        List<ObjectDataHelper.SObjectWrapper> result =
            ObjectDataHelper.getNonSetupObjects();

        Assert.isNotNull(result);
        Assert.isFalse(result.isEmpty(), 'At least one queryable object should exist');
    }

    @isTest
    static void testGetNonSetupObjects_containsKnownStandardObjects() {
        List<ObjectDataHelper.SObjectWrapper> result =
            ObjectDataHelper.getNonSetupObjects();

        Set<String> apiNames = new Set<String>();
        for (ObjectDataHelper.SObjectWrapper w : result) {
            apiNames.add(w.apiName);
        }

        Assert.isTrue(apiNames.contains('Contact'),  'Contact should be in results');
        Assert.isTrue(apiNames.contains('Account'),  'Account should be in results');
        Assert.isTrue(apiNames.contains('Lead'),     'Lead should be in results');
    }

    @isTest
    static void testGetNonSetupObjects_isSortedByLabel() {
        List<ObjectDataHelper.SObjectWrapper> result =
            ObjectDataHelper.getNonSetupObjects();

        for (Integer i = 0; i < result.size() - 1; i++) {
            Assert.isTrue(
                result[i].label.compareTo(result[i + 1].label) <= 0,
                'Results should be sorted ascending by label'
            );
        }
    }

    // ── FieldWrapper ──────────────────────────────────────────────────────────

    @isTest
    static void testFieldWrapper_constructorSetsProperties() {
        ObjectDataHelper.FieldWrapper fw =
            new ObjectDataHelper.FieldWrapper('Email', 'Email', 'Email');

        Assert.areEqual('Email', fw.apiName);
        Assert.areEqual('Email', fw.label);
        Assert.areEqual('Email', fw.dataType);
    }

    @isTest
    static void testFieldWrapper_compareToSortsByLabel() {
        ObjectDataHelper.FieldWrapper aField = new ObjectDataHelper.FieldWrapper('Email',  'Email',  'Email');
        ObjectDataHelper.FieldWrapper zField = new ObjectDataHelper.FieldWrapper('ZField', 'ZField', 'Phone');

        Assert.isTrue(aField.compareTo(zField) < 0,  'Email should sort before ZField');
        Assert.isTrue(zField.compareTo(aField) > 0,  'ZField should sort after Email');
        Assert.areEqual(0, aField.compareTo(aField),  'Same label should return 0');
    }

    // ── getObjectFields ───────────────────────────────────────────────────────

    @isTest
    static void testGetObjectFields_contact_returnsOnlySensitiveFields() {
        List<ObjectDataHelper.FieldWrapper> result =
            ObjectDataHelper.getObjectFields('Contact', RefreshOrg_Utils.MASK_OPERATION_TYPE);

        Assert.isNotNull(result);
        Assert.isTrue(result.size() > 0, 'Contact has Email and Phone fields — list should not be empty');

        // Every returned field must be EMAIL or PHONE type (isSensitiveField contract)
        for (ObjectDataHelper.FieldWrapper fw : result) {
            Boolean isSensitive = fw.dataType == 'Email' || fw.dataType == 'Phone';
            Assert.isTrue(isSensitive, 'Only Email/Phone fields should be returned, got: ' + fw.dataType);
        }
    }

    @isTest
    static void testGetObjectFields_contact_containsEmailAndPhoneFields() {
        List<ObjectDataHelper.FieldWrapper> result =
            ObjectDataHelper.getObjectFields('Contact', RefreshOrg_Utils.MASK_OPERATION_TYPE);

        Set<String> apiNames = new Set<String>();
        for (ObjectDataHelper.FieldWrapper fw : result) {
            apiNames.add(fw.apiName);
        }

        Assert.isTrue(apiNames.contains('Email'), 'Contact.Email should be in results');
        Assert.isTrue(apiNames.contains('Phone'), 'Contact.Phone should be in results');
    }

    @isTest
    static void testGetObjectFields_isSortedByLabel() {
        List<ObjectDataHelper.FieldWrapper> result =
            ObjectDataHelper.getObjectFields('Contact', RefreshOrg_Utils.MASK_OPERATION_TYPE);

        for (Integer i = 0; i < result.size() - 1; i++) {
            Assert.isTrue(
                result[i].label.compareTo(result[i + 1].label) <= 0,
                'Results should be sorted ascending by label'
            );
        }
    }

    @isTest
    static void testGetObjectFields_invalidObjectName_throwsAuraHandledException() {
        String invalidName = 'NonExistent_Object_XYZ__c';
        String expectedMsg = 'Invalid object API name: ' + invalidName;

        try {
            ObjectDataHelper.getObjectFields(invalidName, RefreshOrg_Utils.MASK_OPERATION_TYPE);
            Assert.fail('Expected AuraHandledException was not thrown');
        } catch (AuraHandledException e) {
            Assert.areEqual(expectedMsg, e.getMessage(), 'Exception message should identify the bad API name');
        }
    }

    @isTest
    static void testGetObjectFields_nullObjectName_throwsAuraHandledException() {
        try {
            ObjectDataHelper.getObjectFields(null, RefreshOrg_Utils.MASK_OPERATION_TYPE);
            Assert.fail('Expected AuraHandledException was not thrown');
        } catch (AuraHandledException e) {
            Assert.areEqual('Invalid object API name: null', e.getMessage(),
                'Exception message should handle null API name');
        }
    }

    @isTest
    static void testGetObjectFields_blankObjectName_throwsAuraHandledException() {
        try {
            ObjectDataHelper.getObjectFields('', RefreshOrg_Utils.MASK_OPERATION_TYPE);
            Assert.fail('Expected AuraHandledException was not thrown');
        } catch (AuraHandledException e) {
            Assert.areEqual('Invalid object API name: ', e.getMessage(),
                'Exception message should handle blank API name');
        }
    }
}