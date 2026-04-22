global class Batch_MaskObjectRecordsDetails implements Database.Batchable<sObject>, Database.Stateful {

    public Database.QueryLocator start(Database.BatchableContext bc) {
        return Database.getQueryLocator('SELECT Id, Name, Email, Phone FROM Contact');
    }

    public void execute(Database.BatchableContext bc, List<SObject> scope) {
    }

    public void finish(Database.BatchableContext bc) {
    }
}