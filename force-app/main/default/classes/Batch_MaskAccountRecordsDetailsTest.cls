@isTest
private class Batch_MaskAccountRecordsDetailsTest {

    // ── Helpers ───────────────────────────────────────────────────────────────

    private static Account buildAccount(String name, String phone, String website, String accNumber) {
        return new Account(
            Name = name,
            Phone = phone,
            Website = website,
            AccountNumber = accNumber
        );
    }

    // ── Tests ─────────────────────────────────────────────────────────────────

    @isTest
    static void testExecute_masksAllAccountFields() {
        Account acc = buildAccount('OriginalName', '(111) 111-1111', 'https://original.com', 'ORIG001');
        insert acc;

        Test.startTest();
        Database.executeBatch(new Batch_MaskAccountRecordsDetails(new Set<Id>()));
        Test.stopTest();

        Account updated = [SELECT Name, Phone, Website, AccountNumber FROM Account WHERE Id = :acc.Id];
        Assert.areNotEqual('OriginalName',          updated.Name,          'Name should be masked');
        Assert.areNotEqual('(111) 111-1111',         updated.Phone,         'Phone should be masked');
        Assert.areNotEqual('https://original.com',   updated.Website,       'Website should be masked');
        Assert.areNotEqual('ORIG001',                updated.AccountNumber, 'AccountNumber should be masked');
    }

    @isTest
    static void testExecute_excludesAccountsInExclusionSet() {
        Account acc = buildAccount('ExcludedAccount', '(222) 222-2222', 'https://excluded.com', 'EXCL001');
        insert acc;

        Test.startTest();
        Database.executeBatch(new Batch_MaskAccountRecordsDetails(new Set<Id>{ acc.Id }));
        Test.stopTest();

        Account unchanged = [SELECT Name, Phone, Website, AccountNumber FROM Account WHERE Id = :acc.Id];
        Assert.areEqual('ExcludedAccount',      unchanged.Name,          'Excluded account Name should be unchanged');
        Assert.areEqual('(222) 222-2222',        unchanged.Phone,         'Excluded account Phone should be unchanged');
        Assert.areEqual('https://excluded.com',  unchanged.Website,       'Excluded account Website should be unchanged');
        Assert.areEqual('EXCL001',               unchanged.AccountNumber, 'Excluded account AccountNumber should be unchanged');
    }

    @isTest
    static void testExecute_emptyScope_noException() {
        Test.startTest();
        Database.executeBatch(new Batch_MaskAccountRecordsDetails(new Set<Id>()));
        Test.stopTest();

        Assert.areEqual(0, [SELECT COUNT() FROM Account], 'No accounts should exist');
    }

    @isTest
    static void testExecute_multipleAccounts_allMasked() {
        List<Account> accounts = new List<Account>{
            buildAccount('Acct1', '(111) 111-1111', 'https://acct1.com', 'ACC001'),
            buildAccount('Acct2', '(222) 222-2222', 'https://acct2.com', 'ACC002'),
            buildAccount('Acct3', '(333) 333-3333', 'https://acct3.com', 'ACC003')
        };
        insert accounts;

        Test.startTest();
        Database.executeBatch(new Batch_MaskAccountRecordsDetails(new Set<Id>()));
        Test.stopTest();

        List<Account> updated = [SELECT Name, Phone FROM Account ORDER BY Name];
        for (Account a : updated) {
            Assert.isFalse(
                new Set<String>{'Acct1', 'Acct2', 'Acct3'}.contains(a.Name),
                'All account Names should be masked'
            );
        }
    }

    @isTest
    static void testExecute_partialExclusion_masksOnlyNonExcluded() {
        Account excluded = buildAccount('ExcludedAcct', '(100) 000-0000', 'https://excl.com', 'EXC001');
        Account included = buildAccount('IncludedAcct', '(200) 000-0000', 'https://incl.com', 'INC001');
        insert new List<Account>{ excluded, included };

        Test.startTest();
        Database.executeBatch(new Batch_MaskAccountRecordsDetails(new Set<Id>{ excluded.Id }));
        Test.stopTest();

        Account unchangedAcc = [SELECT Name FROM Account WHERE Id = :excluded.Id];
        Account maskedAcc    = [SELECT Name FROM Account WHERE Id = :included.Id];

        Assert.areEqual('ExcludedAcct', unchangedAcc.Name, 'Excluded account should not be changed');
        Assert.areNotEqual('IncludedAcct', maskedAcc.Name, 'Non-excluded account should be masked');
    }
}
