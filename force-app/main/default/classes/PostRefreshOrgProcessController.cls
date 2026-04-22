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
    public static Map<String, Object> maskContactData(){
        try {
            Batch_MaskQuoteRecordsDetails b = new Batch_MaskQuoteRecordsDetails(); 
            database.executebatch(b);
            return new Map<String, Object>{
                'success' => true,
                'message' => 'Batch class has been initiated'
            };
        } catch (Exception e) {
            throw new AuraHandledException(e.getMessage());
        }
    }
}