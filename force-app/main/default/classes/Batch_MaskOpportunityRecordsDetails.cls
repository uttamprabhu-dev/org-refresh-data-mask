public with sharing class Batch_MaskOpportunityRecordsDetails implements Database.Batchable<sObject>, Database.Stateful {
    Set<Id> set_idAccountIds = new Set<Id>();
    public Database.QueryLocator start(Database.BatchableContext bc) {
        return Database.getQueryLocator(
            'SELECT Id, Name, ' + 
            'AccountId, Account.Phone, Account.Website, Account.AccountNumber ' +
            'FROM Opportunity'
        );
    }

    public void execute(Database.BatchableContext bc, List<Opportunity> scope) {
        List<Opportunity> list_oppsToUpdate = new List<Opportunity>();
        Map<Id, Account> map_accountsToUpdateMap = new Map<Id, Account>();

        for (Opportunity objOpp : scope) {
            // 1. Update Opportunity field (every Opportunity gets updated)
            objOpp.Name = DataMaskHelper.generateRandomString(8, DataMaskHelper.ALPHANUMERIC);
            list_oppsToUpdate.add(objOpp);

            // 3. Update Account field — skip if already updated in a prior chunk
            Id accId = objOpp.AccountId;
            if (accId != null) {
                map_accountsToUpdateMap.put(accId, new Account(
                    Id = accId,
                    Phone = objOpp.Account.Phone == null ? objOpp.Account.Phone : DataMaskHelper.generate_randomPhoneNumber(),
                    Website = objOpp.Account.Website == null ? objOpp.Account.Website : DataMaskHelper.generate_randomUrl(),
                    AccountNumber = objOpp.Account.AccountNumber == null ? objOpp.Account.AccountNumber : DataMaskHelper.generateRandomString(10, DataMaskHelper.ALPHANUMERIC)
                ));
            }
        }

        // DML
        Database.DMLOptions dmo = new Database.DMLOptions();
        dmo.DuplicateRuleHeader.allowSave = true;
        dmo.optAllOrNone = false;

        if (!list_oppsToUpdate.isEmpty()) {
            Database.SaveResult[] results = Database.update(list_oppsToUpdate, dmo);
            for (Database.SaveResult sr : results) {
                if (!sr.isSuccess()) {
                    for (Database.Error err : sr.getErrors()) {
                        System.debug(LoggingLevel.ERROR, 'Batch_MaskOpportunityRecordsDetails Opp Update Error: ' + err.getStatusCode() + ' - ' + err.getMessage());
                    }
                }
            }
        }

        if (!map_accountsToUpdateMap.isEmpty()) {
            Database.SaveResult[] results = Database.update(map_accountsToUpdateMap.values(), dmo);
            for (Database.SaveResult sr : results) {
                if (!sr.isSuccess()) {
                    for (Database.Error err : sr.getErrors()) {
                        System.debug(LoggingLevel.ERROR, 'Batch_MaskOpportunityRecordsDetails Account Update Error: ' + err.getStatusCode() + ' - ' + err.getMessage());
                    }
                }
            }
            set_idAccountIds.addAll(map_accountsToUpdateMap.keySet());
        }
    }

    public void finish(Database.BatchableContext bc) {
        System.debug('Accounts updated: ' + set_idAccountIds.size());

        Batch_MaskAccountRecordsDetails b = new Batch_MaskAccountRecordsDetails(set_idAccountIds); 
        database.executebatch(b);
    }
}