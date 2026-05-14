@isTest
private class Batch_MaskObjectRecordsDetailsTest {

    // ── Helpers ──────────────────────────────────────────────────────────────

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

    // ── Tests ─────────────────────────────────────────────────────────────────

    @isTest
    static void testExecute_masksEmailField() {
        Contact c = new Contact(LastName = 'Test', Email = 'original@test.com');
        insert c;

        List<PostRefreshOrgProcessController.MaskingPayload> payloads =
            new List<PostRefreshOrgProcessController.MaskingPayload>{
                buildPayload('Contact', new List<PostRefreshOrgProcessController.FieldData>{
                    buildFieldData('Email', 'Email')
                })
            };

        Test.startTest();
        Database.executeBatch(new Batch_MaskObjectRecordsDetails(payloads));
        Test.stopTest();

        Contact updated = [SELECT Email FROM Contact WHERE Id = :c.Id];
        Assert.isNotNull(updated.Email, 'Masked email should not be null');
        Assert.areNotEqual('original@test.com', updated.Email, 'Email should have been replaced with a masked value');
    }

    @isTest
    static void testExecute_masksPhoneField() {
        Contact c = new Contact(LastName = 'Test', Phone = '(111) 111-1111');
        insert c;

        List<PostRefreshOrgProcessController.MaskingPayload> payloads =
            new List<PostRefreshOrgProcessController.MaskingPayload>{
                buildPayload('Contact', new List<PostRefreshOrgProcessController.FieldData>{
                    buildFieldData('Phone', 'Phone')
                })
            };

        Test.startTest();
        Database.executeBatch(new Batch_MaskObjectRecordsDetails(payloads));
        Test.stopTest();

        Contact updated = [SELECT Phone FROM Contact WHERE Id = :c.Id];
        Assert.isNotNull(updated.Phone, 'Masked phone should not be null');
        Assert.areNotEqual('(111) 111-1111', updated.Phone, 'Phone should have been replaced with a masked value');
    }

    @isTest
    static void testExecute_masksBothEmailAndPhone() {
        Contact c = new Contact(LastName = 'Test', Email = 'original@test.com', Phone = '(111) 111-1111');
        insert c;

        List<PostRefreshOrgProcessController.MaskingPayload> payloads =
            new List<PostRefreshOrgProcessController.MaskingPayload>{
                buildPayload('Contact', new List<PostRefreshOrgProcessController.FieldData>{
                    buildFieldData('Email', 'Email'),
                    buildFieldData('Phone', 'Phone')
                })
            };

        Test.startTest();
        Database.executeBatch(new Batch_MaskObjectRecordsDetails(payloads));
        Test.stopTest();

        Contact updated = [SELECT Email, Phone FROM Contact WHERE Id = :c.Id];
        Assert.areNotEqual('original@test.com', updated.Email, 'Email should have been masked');
        Assert.areNotEqual('(111) 111-1111', updated.Phone, 'Phone should have been masked');
    }

    @isTest
    static void testExecute_emptyScope_noException() {
        // No records — execute() must skip the DML branch without throwing
        List<PostRefreshOrgProcessController.MaskingPayload> payloads =
            new List<PostRefreshOrgProcessController.MaskingPayload>{
                buildPayload('Contact', new List<PostRefreshOrgProcessController.FieldData>{
                    buildFieldData('Email', 'Email')
                })
            };

        Test.startTest();
        Database.executeBatch(new Batch_MaskObjectRecordsDetails(payloads));
        Test.stopTest();

        Assert.areEqual(0, [SELECT COUNT() FROM Contact], 'No records should exist');
    }

    @isTest
    static void testFinish_singlePayload_doesNotChain() {
        // finish() should return without starting another batch
        Contact c = new Contact(LastName = 'Test', Email = 'test@original.com');
        insert c;

        List<PostRefreshOrgProcessController.MaskingPayload> payloads =
            new List<PostRefreshOrgProcessController.MaskingPayload>{
                buildPayload('Contact', new List<PostRefreshOrgProcessController.FieldData>{
                    buildFieldData('Email', 'Email')
                })
            };

        Test.startTest();
        Database.executeBatch(new Batch_MaskObjectRecordsDetails(payloads));
        Test.stopTest();

        Contact updated = [SELECT Email FROM Contact WHERE Id = :c.Id];
        Assert.areNotEqual('test@original.com', updated.Email, 'Email should have been masked');
    }

    @isTest
    static void testFinish_multiplePayloads_chainsNextBatch() {
        // finish() should chain a new batch for the remaining payload
        Contact c = new Contact(LastName = 'ContactTest', Email = 'contact@original.com');
        insert c;
        Lead l = new Lead(LastName = 'LeadTest', Company = 'TestCo', Phone = '(222) 222-2222');
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
        Database.executeBatch(new Batch_MaskObjectRecordsDetails(payloads));
        Test.stopTest();

        Contact updatedContact = [SELECT Email FROM Contact WHERE Id = :c.Id];
        Lead updatedLead = [SELECT Phone FROM Lead WHERE Id = :l.Id];
        Assert.areNotEqual('contact@original.com', updatedContact.Email, 'Contact email should be masked by first batch');
        Assert.areNotEqual('(222) 222-2222', updatedLead.Phone, 'Lead phone should be masked by chained batch');
    }
}
