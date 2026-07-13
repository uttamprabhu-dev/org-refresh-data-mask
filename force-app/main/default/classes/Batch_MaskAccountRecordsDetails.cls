public class Batch_MaskAccountRecordsDetails implements Database.Batchable<sObject>, Database.Stateful {
    Set<Id> set_idAccountIds = new Set<Id>();
    public Batch_MaskAccountRecordsDetails(Set<Id> set_idAccountIds) {
        this.set_idAccountIds = set_idAccountIds;
    }

    public Database.QueryLocator start(Database.BatchableContext bc) {
        return Database.getQueryLocator(
            'SELECT Id, Name, Phone, Website, AccountNumber ' +
            'FROM Account ' +
            'WHERE Id NOT IN :set_idAccountIds'
        );
    }

    public void execute(Database.BatchableContext bc, List<Account> scope) {
        List<Account> list_accountsToUpdate = new List<Account>();
        Map<Id, Account> map_accountsToUpdateMap = new Map<Id, Account>();

        for (Account acc : scope) {
            // 1. Update Account field (every account gets updated)
            acc.Name = DataMaskHelper.generateRandomString(8, DataMaskHelper.ALPHANUMERIC);
            acc.Phone = DataMaskHelper.generate_randomPhoneNumber();
            acc.Website = DataMaskHelper.generate_randomUrl();
            acc.AccountNumber = DataMaskHelper.generateRandomString(10, DataMaskHelper.ALPHANUMERIC);
            list_accountsToUpdate.add(acc);
        }

        // DML
        if (!list_accountsToUpdate.isEmpty()) {
            Database.DMLOptions dmo = new Database.DMLOptions();
            dmo.DuplicateRuleHeader.allowSave = true;
            dmo.optAllOrNone = false;
            Database.SaveResult[] results = Database.update(list_accountsToUpdate, dmo);
            for (Database.SaveResult sr : results) {
                if (!sr.isSuccess()) {
                    for (Database.Error err : sr.getErrors()) {
                        System.debug(LoggingLevel.ERROR, 'Batch_MaskAccountRecordsDetails Update Error: ' + err.getStatusCode() + ' - ' + err.getMessage());
                    }
                }
            }
        }
    }

    public void finish(Database.BatchableContext bc) {
        System.debug('Accounts updated: ' + set_idAccountIds.size());
    }
}