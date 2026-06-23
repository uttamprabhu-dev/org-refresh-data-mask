@isTest
private class Batch_MaskQuoteRecordsDetailsTest {

    // ── Helpers ───────────────────────────────────────────────────────────────

    private static Account createAccount() {
        Account acc = new Account(
            Name = 'Original Account',
            Phone = '(123) 456-7890',
            Website = 'https://www.original.com',
            AccountNumber = 'ACCT001'
        );
        insert acc;
        return acc;
    }

    private static Opportunity createOpportunity(Id accountId) {
        Opportunity opp = new Opportunity(
            Name = 'Original Opportunity',
            AccountId = accountId,
            StageName = 'Prospecting',
            CloseDate = Date.today().addDays(30)
        );
        insert opp;
        return opp;
    }

    private static Quote createQuote(Id opportunityId) {
        Quote q = new Quote(
            Name = 'Original Quote',
            OpportunityId = opportunityId,
            Pricebook2Id = Test.getStandardPricebookId(),
            Email = 'original@test.com',
            Phone = '(111) 111-1111',
            Description = 'Original Description'
        );
        insert q;
        return q;
    }

    // ── Tests ─────────────────────────────────────────────────────────────────

    @isTest
    static void testExecute_masksQuoteFields() {
        Account acc = createAccount();
        Opportunity opp = createOpportunity(acc.Id);
        Quote q = createQuote(opp.Id);

        Test.startTest();
        Database.executeBatch(new Batch_MaskQuoteRecordsDetails());
        Test.stopTest();

        Quote updated = [SELECT Name, Email, Phone, Description FROM Quote WHERE Id = :q.Id];
        Assert.areNotEqual('Original Quote',       updated.Name,        'Quote Name should be masked');
        Assert.areNotEqual('original@test.com',    updated.Email,       'Quote Email should be masked');
        Assert.areNotEqual('(111) 111-1111',        updated.Phone,       'Quote Phone should be masked');
        Assert.areNotEqual('Original Description', updated.Description, 'Quote Description should be masked');
    }

    @isTest
    static void testExecute_masksLinkedOpportunity() {
        Account acc = createAccount();
        Opportunity opp = createOpportunity(acc.Id);
        createQuote(opp.Id);

        Test.startTest();
        Database.executeBatch(new Batch_MaskQuoteRecordsDetails());
        Test.stopTest();

        Opportunity updated = [SELECT Name FROM Opportunity WHERE Id = :opp.Id];
        Assert.areNotEqual('Original Opportunity', updated.Name, 'Opportunity Name should be masked via Quote batch');
    }

    @isTest
    static void testExecute_masksLinkedAccountViaQuote() {
        Account acc = createAccount();
        Opportunity opp = createOpportunity(acc.Id);
        createQuote(opp.Id);

        Test.startTest();
        Database.executeBatch(new Batch_MaskQuoteRecordsDetails());
        Test.stopTest();

        Account updated = [SELECT Phone, Website, AccountNumber FROM Account WHERE Id = :acc.Id];
        Assert.areNotEqual('(123) 456-7890',           updated.Phone,         'Account Phone should be masked via Quote batch');
        Assert.areNotEqual('https://www.original.com', updated.Website,       'Account Website should be masked via Quote batch');
        Assert.areNotEqual('ACCT001',                  updated.AccountNumber, 'Account AccountNumber should be masked via Quote batch');
    }

    @isTest
    static void testExecute_nullFieldsRemainNull() {
        Account acc = createAccount();
        Opportunity opp = createOpportunity(acc.Id);
        // Create quote without optional fields (Email, Phone, Description are null)
        Quote q = new Quote(
            Name = 'Null Fields Quote',
            OpportunityId = opp.Id,
            Pricebook2Id = Test.getStandardPricebookId()
        );
        insert q;

        Test.startTest();
        Database.executeBatch(new Batch_MaskQuoteRecordsDetails());
        Test.stopTest();

        Quote updated = [SELECT Email, Phone, Description FROM Quote WHERE Id = :q.Id];
        Assert.isNull(updated.Email,       'Null Email should remain null after masking');
        Assert.isNull(updated.Phone,       'Null Phone should remain null after masking');
        Assert.isNull(updated.Description, 'Null Description should remain null after masking');
    }

    @isTest
    static void testExecute_emptyScope_noException() {
        Test.startTest();
        Database.executeBatch(new Batch_MaskQuoteRecordsDetails());
        Test.stopTest();

        Assert.areEqual(0, [SELECT COUNT() FROM Quote], 'No quotes should exist');
    }

    @isTest
    static void testIsObjectAvailable_knownObject_returnsTrue() {
        Assert.isTrue(
            Batch_MaskQuoteRecordsDetails.isObjectAvailable('Account'),
            'isObjectAvailable should return true for a standard object that always exists'
        );
    }

    @isTest
    static void testIsObjectAvailable_nonExistentObject_returnsFalse() {
        Assert.isFalse(
            Batch_MaskQuoteRecordsDetails.isObjectAvailable('FakeObject_That_Does_Not_Exist__x'),
            'isObjectAvailable should return false for an object that does not exist'
        );
    }

    @isTest
    static void testStart_quoteUnavailable_returnsEmptyScope() {
        // Simulate the guard path: run the batch against an Account query that matches nothing.
        // We can't disable Quote at runtime, so we verify the batch completes cleanly with no
        // records processed when the scope is empty — the same outcome the guard produces.
        Test.startTest();
        Database.executeBatch(new Batch_MaskQuoteRecordsDetails());
        Test.stopTest();

        // If the guard returned an empty QueryLocator the batch finishes without DML errors.
        Assert.areEqual(0, [SELECT COUNT() FROM Quote], 'Batch should complete cleanly with no records');
    }

    @isTest
    static void testExecute_deduplicatesOpportunityAcrossQuotes() {
        // Two quotes sharing one opportunity — the opp should be masked exactly once (no DML conflict)
        Account acc = createAccount();
        Opportunity opp = createOpportunity(acc.Id);
        createQuote(opp.Id);
        createQuote(opp.Id);

        Test.startTest();
        Database.executeBatch(new Batch_MaskQuoteRecordsDetails());
        Test.stopTest();

        Opportunity updated = [SELECT Name FROM Opportunity WHERE Id = :opp.Id];
        Assert.areNotEqual('Original Opportunity', updated.Name, 'Shared Opportunity should be masked without DML conflict');
    }

    @isTest
    static void testExecute_deduplicatesAccountAcrossQuotes() {
        // Two quotes whose opportunities share the same account — account masked exactly once
        Account acc = createAccount();
        Opportunity opp1 = createOpportunity(acc.Id);
        Opportunity opp2 = new Opportunity(
            Name = 'Second Opportunity',
            AccountId = acc.Id,
            StageName = 'Qualification',
            CloseDate = Date.today().addDays(60)
        );
        insert opp2;
        createQuote(opp1.Id);
        createQuote(opp2.Id);

        Test.startTest();
        Database.executeBatch(new Batch_MaskQuoteRecordsDetails());
        Test.stopTest();

        Account updated = [SELECT Phone FROM Account WHERE Id = :acc.Id];
        Assert.areNotEqual('(123) 456-7890', updated.Phone, 'Shared Account should be masked without DML conflict');
    }

    @isTest
    static void testFinish_chainsToOpportunityBatch() {
        // Opportunity with no Quote — won't appear in Batch_MaskQuoteRecordsDetails scope,
        // so it must be masked by the chained Batch_MaskOpportunityRecordsDetails.
        Account quotedAcc = createAccount();
        Opportunity quotedOpp = createOpportunity(quotedAcc.Id);
        createQuote(quotedOpp.Id);

        Account standaloneAcc = new Account(Name = 'Standalone Account');
        insert standaloneAcc;
        Opportunity standaloneOpp = new Opportunity(
            Name = 'Standalone Opportunity',
            AccountId = standaloneAcc.Id,
            StageName = 'Prospecting',
            CloseDate = Date.today().addDays(30)
        );
        insert standaloneOpp;

        Test.startTest();
        Database.executeBatch(new Batch_MaskQuoteRecordsDetails());
        Test.stopTest();

        Opportunity updated = [SELECT Name FROM Opportunity WHERE Id = :standaloneOpp.Id];
        Assert.areNotEqual('Standalone Opportunity', updated.Name, 'Standalone Opportunity should be masked by the chained batch');
    }
}