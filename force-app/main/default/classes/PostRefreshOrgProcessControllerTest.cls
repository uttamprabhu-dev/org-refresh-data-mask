@isTest
private class PostRefreshOrgProcessControllerTest {

    // ── Helpers ───────────────────────────────────────────────────────────────

    private static PostRefreshOrgProcessController.FieldData buildFieldData(String apiName, String dataType) {
        PostRefreshOrgProcessController.FieldData fd = new PostRefreshOrgProcessController.FieldData();
        fd.fieldApiName = apiName;
        fd.fieldDataType = dataType;
        return fd;
    }

    private static PostRefreshOrgProcessController.MaskingPayload buildPayload(
        String objectApiName,
        List<PostRefreshOrgProcessController.FieldData> fields
    ) {
        PostRefreshOrgProcessController.MaskingPayload p = new PostRefreshOrgProcessController.MaskingPayload();
        p.objectApiName = objectApiName;
        p.fields = fields;
        return p;
    }

    // ── getAccountFieldApiNames ───────────────────────────────────────────────

    @isTest
    static void testGetAccountFieldApiNames_returnsNonEmptyList() {
        List<String> fieldNames = PostRefreshOrgProcessController.getAccountFieldApiNames();

        Assert.isNotNull(fieldNames, 'Return value should not be null');
        Assert.isTrue(fieldNames.size() > 0, 'Account has fields — list should not be empty');
    }

    @isTest
    static void testGetAccountFieldApiNames_containsKnownAccountFields() {
        List<String> fieldNames = PostRefreshOrgProcessController.getAccountFieldApiNames();

        // Schema.getMap() keys are lowercased API names
        Assert.isTrue(fieldNames.contains('name'), 'Result should include the Name field');
        Assert.isTrue(fieldNames.contains('phone'), 'Result should include the Phone field');
        Assert.isTrue(fieldNames.contains('id'), 'Result should include the Id field');
    }

    // ── maskStandardData ──────────────────────────────────────────────────────

    @isTest
    static void testMaskStandardData_returnsSuccess() {
        Test.startTest();
        Map<String, Object> result = PostRefreshOrgProcessController.maskStandardData();
        Test.stopTest();

        Assert.isNotNull(result, 'Return map should not be null');
        Assert.areEqual(true, result.get('success'), 'success flag should be true');
        Assert.isNotNull(result.get('message'), 'message should be present');
    }

    // ── maskCustomData ────────────────────────────────────────────────────────

    @isTest
    static void testMaskCustomData_singlePayload_returnsSuccessWithBatchJobId() {
        Contact c = new Contact(LastName = 'Test', Email = 'original@test.com');
        insert c;

        List<PostRefreshOrgProcessController.MaskingPayload> payloads =
            new List<PostRefreshOrgProcessController.MaskingPayload>{
                buildPayload('Contact', new List<PostRefreshOrgProcessController.FieldData>{
                    buildFieldData('Email', 'Email')
                })
            };

        Test.startTest();
        Map<String, Object> result = PostRefreshOrgProcessController.maskCustomData(payloads);
        Test.stopTest();

        Assert.isNotNull(result, 'Return map should not be null');
        Assert.areEqual(true, result.get('success'), 'success flag should be true');
        Assert.isNotNull(result.get('batchJobId'), 'batchJobId should be present');
        Assert.isNotNull(result.get('message'), 'message should be present');
    }

    @isTest
    static void testMaskCustomData_multiplePayloads_returnsSuccess() {
        Contact c = new Contact(LastName = 'Test', Email = 'contact@original.com');
        insert c;
        Lead l = new Lead(LastName = 'LeadTest', Company = 'TestCo', Phone = '(333) 333-3333');
        insert l;

        List<PostRefreshOrgProcessController.MaskingPayload> payloads =
            new List<PostRefreshOrgProcessController.MaskingPayload>{
                buildPayload('Contact', new List<PostRefreshOrgProcessController.FieldData>{
                    buildFieldData('Email', 'Email')
                }),
                buildPayload('Lead', new List<PostRefreshOrgProcessController.FieldData>{
                    buildFieldData('Phone', 'Phone')
                })
            };

        Test.startTest();
        Map<String, Object> result = PostRefreshOrgProcessController.maskCustomData(payloads);
        Test.stopTest();

        Assert.areEqual(true, result.get('success'), 'success flag should be true');
        Assert.isNotNull(result.get('batchJobId'), 'batchJobId should be present');
    }

    @isTest
    static void testMaskCustomData_masksRecordsAfterBatchRuns() {
        Contact c = new Contact(LastName = 'Test', Email = 'original@test.com', Phone = '(444) 444-4444');
        insert c;

        List<PostRefreshOrgProcessController.MaskingPayload> payloads =
            new List<PostRefreshOrgProcessController.MaskingPayload>{
                buildPayload('Contact', new List<PostRefreshOrgProcessController.FieldData>{
                    buildFieldData('Email', 'Email'),
                    buildFieldData('Phone', 'Phone')
                })
            };

        Test.startTest();
        PostRefreshOrgProcessController.maskCustomData(payloads);
        Test.stopTest();

        Contact updated = [SELECT Email, Phone FROM Contact WHERE Id = :c.Id];
        Assert.areNotEqual('original@test.com', updated.Email, 'Email should have been masked by the batch');
        Assert.areNotEqual('(444) 444-4444', updated.Phone, 'Phone should have been masked by the batch');
    }

    // ── Inner classes ─────────────────────────────────────────────────────────

    @isTest
    static void testMaskingPayload_fieldsAreSettable() {
        PostRefreshOrgProcessController.MaskingPayload payload = new PostRefreshOrgProcessController.MaskingPayload();
        payload.objectApiName = 'Contact';
        payload.fields = new List<PostRefreshOrgProcessController.FieldData>{
            buildFieldData('Email', 'Email')
        };

        Assert.areEqual('Contact', payload.objectApiName);
        Assert.areEqual(1, payload.fields.size());
    }

    @isTest
    static void testFieldData_fieldsAreSettable() {
        PostRefreshOrgProcessController.FieldData fd = new PostRefreshOrgProcessController.FieldData();
        fd.fieldApiName = 'Email';
        fd.fieldDataType = 'Email';

        Assert.areEqual('Email', fd.fieldApiName);
        Assert.areEqual('Email', fd.fieldDataType);
    }
}