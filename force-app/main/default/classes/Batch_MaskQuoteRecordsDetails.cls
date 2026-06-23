public class Batch_MaskQuoteRecordsDetails implements Database.Batchable<sObject>, Database.Stateful {

    // Persisted across all batch chunks
    private Set<Id> set_idOpprtntyIds = new Set<Id>();
    private Set<Id> set_idAccountIds = new Set<Id>();

    @TestVisible private static Boolean isObjectAvailable(String objectName) {
        return Schema.getGlobalDescribe().containsKey(objectName);
    }

    public Database.QueryLocator start(Database.BatchableContext bc) {
        if (!isObjectAvailable('Quote')) {
            return Database.getQueryLocator('SELECT Id FROM Account WHERE Id = null');
        }
        return Database.getQueryLocator(
            'SELECT Id, Name, Email, Phone, Description, ' +
            'OpportunityId, Opportunity.Name, ' +
            'Opportunity.AccountId, Opportunity.Account.Phone, Opportunity.Account.Website, Opportunity.Account.AccountNumber ' +
            'FROM Quote ' +
            'WHERE OpportunityId != null'
        );
    }

    public void execute(Database.BatchableContext bc, List<SObject> scope) {
        List<Quote> quotes = (List<Quote>) scope;
        List<Quote> quotesToUpdate = new List<Quote>();
        Map<Id, Opportunity>map_oppsToUpdate = new Map<Id, Opportunity>();
        Map<Id, Account> map_accountsToUpdate = new Map<Id, Account>();

        for (Quote q : quotes) {

            // 1. Update Quote field (every quote gets updated)
            q.Name = DataMaskHelper.generateRandomString(8, DataMaskHelper.ALPHANUMERIC);
            q.Email = q.Email == null ? q.Email : DataMaskHelper.generate_randomEmail();
            q.Phone = q.Phone == null? q.Phone : DataMaskHelper.generate_randomPhoneNumber();
            q.Description = q.Description == null ? q.Description : DataMaskHelper.generateRandomString(20, DataMaskHelper.ALPHANUMERIC);
            quotesToUpdate.add(q);

            // 2. Update Opportunity field — skip if already updated in a prior chunk
            if (q.OpportunityId != null && !set_idOpprtntyIds.contains(q.OpportunityId)) {
                map_oppsToUpdate.put(q.OpportunityId, new Opportunity(
                    Id = q.OpportunityId,
                    Name = DataMaskHelper.generateRandomString(9, DataMaskHelper.ALPHANUMERIC)
                ));
            }

            // 3. Update Account field — skip if already updated in a prior chunk
            Id accId = q.Opportunity?.AccountId;
            if (accId != null && !set_idAccountIds.contains(accId)) {
                map_accountsToUpdate.put(accId, new Account(
                    Id = accId,
                    Phone = q.Opportunity.Account.Phone == null ? q.Opportunity.Account.Phone : DataMaskHelper.generate_randomPhoneNumber(),
                    Website = q.Opportunity.Account.Website == null ? q.Opportunity.Account.Website : DataMaskHelper.generate_randomUrl(),
                    AccountNumber = q.Opportunity.Account.AccountNumber == null ? q.Opportunity.Account.AccountNumber : DataMaskHelper.generateRandomString(10, DataMaskHelper.ALPHANUMERIC)
                ));
            }
        }

        // DML
        if (!quotesToUpdate.isEmpty()) update quotesToUpdate;

        if (!map_oppsToUpdate.isEmpty()) {
            update map_oppsToUpdate.values();
            set_idOpprtntyIds.addAll(map_oppsToUpdate.keySet()); // mark as done
        }

        if (!map_accountsToUpdate.isEmpty()) {
            update map_accountsToUpdate.values();
            set_idAccountIds.addAll(map_accountsToUpdate.keySet()); // mark as done
        }
    }

    public void finish(Database.BatchableContext bc) {
        System.debug('Batch finished. Opportunities updated: ' + set_idOpprtntyIds.size());
        System.debug('Accounts updated: ' + set_idAccountIds.size());

        Batch_MaskOpportunityRecordsDetails b = new Batch_MaskOpportunityRecordsDetails(set_idOpprtntyIds, set_idAccountIds); 
        database.executebatch(b);
    }
}