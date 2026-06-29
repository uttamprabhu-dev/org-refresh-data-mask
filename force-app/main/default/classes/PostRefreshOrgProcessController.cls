public with sharing class PostRefreshOrgProcessController {

    /**
     * Fetches all fields of the Account object and returns their API names
     */
    public static List<String> getAccountFieldApiNames() {
        List<String> fieldApiNames = new List<String>();
        Map<String, Schema.SObjectField> fieldMap = Schema.SObjectType.Account.fields.getMap();

        for (String fieldName : fieldMap.keySet()) {
            fieldApiNames.add(fieldName);
        }

        return fieldApiNames;
    }

    @AuraEnabled
    public static Map<String, Object> maskStandardData(){
        try {
            Database.executeBatch(new Batch_MaskOpportunityRecordsDetails());
            return new Map<String, Object>{
                'success' => true,
                'message' => 'Batch class has been initiated'
            };
        } catch (Exception e) {
            throw new AuraHandledException(e.getMessage());
        }
    }

    public class MaskingPayload {
        @AuraEnabled public String objectApiName { get; set; }
        @AuraEnabled public List<FieldData> fields { get; set; }
    }
    public class FieldData {
        @AuraEnabled public String fieldApiName { get; set; }
        @AuraEnabled public String fieldDataType { get; set; }
        @AuraEnabled public Integer fromChar { get; set; }
        @AuraEnabled public Integer toChar { get; set; }
    }

    @AuraEnabled
    public static Map<String, Object> maskCustomData(List<MaskingPayload> payload){
        try {
            System.debug('Payload received: ' + JSON.serialize(payload));
            Batch_MaskObjectRecordsDetails batch_maskRecordsJob = new Batch_MaskObjectRecordsDetails(payload);
            Id idBatchJobID = Database.executeBatch(batch_maskRecordsJob);
            return new Map<String, Object>{
                'success' => true,
                'batchJobId' => idBatchJobID,
                'message' => 'Batch class has been initiated'
            };
        } catch (Exception e) {
            throw new AuraHandledException(e.getMessage());
        }
    }

    
    @AuraEnabled
    public static Map<String, Object> redactCustomData(List<MaskingPayload> payload){
        try {
            System.debug('Payload received: ' + JSON.serialize(payload));
            Batch_RedactObjectRecordDetails batch_maskRecordsJob = new Batch_RedactObjectRecordDetails(payload);
            Id idBatchJobID = Database.executeBatch(batch_maskRecordsJob);
            return new Map<String, Object>{
                'success' => true,
                'batchJobId' => idBatchJobID,
                'message' => 'Batch class has been initiated'
            };
        } catch (Exception e) {
            throw new AuraHandledException(e.getMessage());
        }
    }
}