public class Batch_MaskOpportunityRecordsDetails implements Database.Batchable<sObject>, Database.Stateful {
    Set<Id> set_idOpprtntyIds = new Set<Id>();
    Set<Id> set_idAccountIds = new Set<Id>();
    public Batch_MaskOpportunityRecordsDetails(Set<Id> set_idOpprtntyIds, Set<Id> set_idAccountIds) {
        this.set_idOpprtntyIds = set_idOpprtntyIds;
        this.set_idAccountIds = set_idAccountIds;
    }

    public Database.QueryLocator start(Database.BatchableContext bc) {
        return Database.getQueryLocator(
            'SELECT Id, Name, ' + 
            'AccountId, Account.Phone, Account.Website, Account.AccountNumber ' +
            'FROM Opportunity ' +
            'WHERE Id NOT IN :set_idOpprtntyIds'
        );
    }

    public void execute(Database.BatchableContext bc, List<Opportunity> scope) {
        List<Opportunity> list_oppsToUpdate = new List<Opportunity>();
        Map<Id, Account> map_accountsToUpdateMap = new Map<Id, Account>();

        for (Opportunity objOpp : scope) {
            // 1. Update Quote field (every quote gets updated)
            objOpp.Name = DataMaskHelper.generateRandomString(8, DataMaskHelper.ALPHANUMERIC);
            list_oppsToUpdate.add(objOpp);

            // 3. Update Account field — skip if already updated in a prior chunk
            Id accId = objOpp.AccountId;
            if (accId != null && !set_idAccountIds.contains(accId)) {
                map_accountsToUpdateMap.put(accId, new Account(
                    Id = accId,
                    Phone = objOpp.Account.Phone == null ? objOpp.Account.Phone : DataMaskHelper.generate_randomPhoneNumber(),
                    Website = objOpp.Account.Website == null ? objOpp.Account.Website : DataMaskHelper.generate_randomUrl(),
                    AccountNumber = objOpp.Account.AccountNumber == null ? objOpp.Account.AccountNumber : DataMaskHelper.generateRandomString(10, DataMaskHelper.ALPHANUMERIC)
                ));
            }
        }

        // DML
        if (!list_oppsToUpdate.isEmpty()) update list_oppsToUpdate;

        if (!map_accountsToUpdateMap.isEmpty()) {
            update map_accountsToUpdateMap.values();
            set_idAccountIds.addAll(map_accountsToUpdateMap.keySet()); // mark as done
        }
    }

    public void finish(Database.BatchableContext bc) {
        System.debug('Batch finished. Opportunities updated: ' + set_idOpprtntyIds.size());
        System.debug('Accounts updated: ' + set_idAccountIds.size());

        Batch_MaskAccountRecordsDetails b = new Batch_MaskAccountRecordsDetails(set_idAccountIds); 
        database.executebatch(b);
    }
}