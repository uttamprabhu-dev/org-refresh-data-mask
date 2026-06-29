@isTest
private class Batch_MaskOpportunityRecordsDetailsTest {

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

    // ── Tests ─────────────────────────────────────────────────────────────────

    @isTest
    static void testExecute_masksOpportunityName() {
        Account acc = createAccount();
        Opportunity opp = createOpportunity(acc.Id);

        Test.startTest();
        Database.executeBatch(new Batch_MaskOpportunityRecordsDetails());
        Test.stopTest();

        Opportunity updated = [SELECT Name FROM Opportunity WHERE Id = :opp.Id];
        Assert.areNotEqual('Original Opportunity', updated.Name, 'Opportunity Name should be masked');
    }

    @isTest
    static void testExecute_masksLinkedAccountFields() {
        Account acc = createAccount();
        createOpportunity(acc.Id);

        Test.startTest();
        Database.executeBatch(new Batch_MaskOpportunityRecordsDetails());
        Test.stopTest();

        Account updated = [SELECT Phone, Website, AccountNumber FROM Account WHERE Id = :acc.Id];
        Assert.areNotEqual('(123) 456-7890',          updated.Phone,         'Account Phone should be masked');
        Assert.areNotEqual('https://www.original.com', updated.Website,       'Account Website should be masked');
        Assert.areNotEqual('ACCT001',                  updated.AccountNumber, 'Account AccountNumber should be masked');
    }

    @isTest
    static void testExecute_emptyScope_noException() {
        Test.startTest();
        Database.executeBatch(new Batch_MaskOpportunityRecordsDetails());
        Test.stopTest();

        Assert.areEqual(0, [SELECT COUNT() FROM Opportunity], 'No opportunities should exist');
    }

    @isTest
    static void testFinish_chainsToAccountBatch() {
        // Standalone account (not linked to any opp) — the Opp batch won't touch it,
        // so Batch_MaskAccountRecordsDetails chained from finish() should mask its Name.
        Account standaloneAcc = new Account(Name = 'StandaloneAccount');
        insert standaloneAcc;

        Account linkedAcc = createAccount();
        createOpportunity(linkedAcc.Id);

        Test.startTest();
        Database.executeBatch(new Batch_MaskOpportunityRecordsDetails());
        Test.stopTest();

        Account updated = [SELECT Name FROM Account WHERE Id = :standaloneAcc.Id];
        Assert.areNotEqual('StandaloneAccount', updated.Name, 'Standalone account Name should be masked by the chained batch');
    }

    @isTest
    static void testExecute_multipleOpportunities_allMasked() {
        Account acc = createAccount();
        Opportunity opp1 = createOpportunity(acc.Id);
        Account acc2 = new Account(Name = 'Second Account');
        insert acc2;
        Opportunity opp2 = new Opportunity(
            Name = 'Second Opportunity',
            AccountId = acc2.Id,
            StageName = 'Qualification',
            CloseDate = Date.today().addDays(60)
        );
        insert opp2;

        Test.startTest();
        Database.executeBatch(new Batch_MaskOpportunityRecordsDetails());
        Test.stopTest();

        List<Opportunity> updated = [SELECT Name FROM Opportunity ORDER BY Name];
        for (Opportunity o : updated) {
            Assert.isFalse(
                new Set<String>{'Original Opportunity', 'Second Opportunity'}.contains(o.Name),
                'All opportunity Names should be masked'
            );
        }
    }
}