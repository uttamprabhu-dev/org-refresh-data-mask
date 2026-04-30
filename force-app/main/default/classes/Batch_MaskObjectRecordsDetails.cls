global class Batch_MaskObjectRecordsDetails implements Database.Batchable<SObject>, Database.Stateful {
    private List<PostRefreshOrgProcessController.MaskingPayload> payload;
    private String query;
    private Map<String, Schema.DisplayType> map_apiNameToDisplayType = new Map<String, Schema.DisplayType>(); 

    public Batch_MaskObjectRecordsDetails(List<PostRefreshOrgProcessController.MaskingPayload> payload) {
        this.payload = payload;
        this.query = generateQuery(payload[0]);
    }

    private String generateQuery(PostRefreshOrgProcessController.MaskingPayload maskingPayload) {Map<String, Schema.SObjectField> fieldMap = Schema.getGlobalDescribe().get(maskingPayload.objectApiName).getDescribe().fields.getMap();
        String query = 'SELECT Id, ';
        for(PostRefreshOrgProcessController.FieldData field : maskingPayload.fields){
            query += field.fieldApiName + ',';
            Schema.DisplayType fieldType = Schema.DisplayType.valueOf(field.fieldDataType);
            map_apiNameToDisplayType.put(field.fieldApiName, fieldType);
        }
        query = query.removeEnd(',');
        query += ' FROM ' + maskingPayload.objectApiName + ' WHERE Id != null';
        return query;
    }
    
    public Database.QueryLocator start(Database.BatchableContext bc) {
        return Database.getQueryLocator(query);
    }
    
    public void execute(Database.BatchableContext bc, List<SObject> scope) {
        List<SObject> list_recordsToUpdate = new List<SObject>();
        // process scope records
        for (SObject record : scope) {
            for (String fieldApiName : map_apiNameToDisplayType.keySet()) {
                // only modify sensitive fields
                if (map_apiNameToDisplayType.get(fieldApiName) == Schema.DisplayType.Email) {
                    String strMaskedEmail = DataMaskHelper.generate_randomEmail();
                    record.put(fieldApiName, strMaskedEmail);
                } else if (map_apiNameToDisplayType.get(fieldApiName) == Schema.DisplayType.Phone) {
                    String strMaskedPhone = DataMaskHelper.generate_randomPhoneNumber();
                    record.put(fieldApiName, strMaskedPhone);
                }
            }
            list_recordsToUpdate.add(record);
        }
        // 5. Single DML statement for all records
        if (!list_recordsToUpdate.isEmpty()) {
            update list_recordsToUpdate;
        }
    }
    
    public void finish(Database.BatchableContext bc) {

        List<PostRefreshOrgProcessController.MaskingPayload> remainingPayload = new List<PostRefreshOrgProcessController.MaskingPayload>(payload);
        remainingPayload.remove(0);

        if (remainingPayload.isEmpty()) {
            return;
        }
        
        Database.executeBatch(new Batch_MaskObjectRecordsDetails(remainingPayload));
    }
}