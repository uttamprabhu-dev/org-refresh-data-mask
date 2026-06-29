public class Batch_RedactObjectRecordDetails implements Database.Batchable<SObject>, Database.Stateful {

    private List<PostRefreshOrgProcessController.MaskingPayload> payload;
    private String query;
    private Map<String, Schema.DisplayType> map_apiNameToDisplayType = new Map<String, Schema.DisplayType>();
    private Map<String, CustomCharWrapper> map_apiNameToCharCount = new Map<String, CustomCharWrapper>();

    public Batch_RedactObjectRecordDetails(List<PostRefreshOrgProcessController.MaskingPayload> payload) {
        this.payload = payload;
        this.query = generateQuery(this.payload[0]);
    }

    private String generateQuery(PostRefreshOrgProcessController.MaskingPayload maskingPayload) {Map<String, Schema.SObjectField> fieldMap = Schema.getGlobalDescribe().get(maskingPayload.objectApiName).getDescribe().fields.getMap();
        String query = 'SELECT Id, ';
        for(PostRefreshOrgProcessController.FieldData field : maskingPayload.fields){
            query += field.fieldApiName + ',';
            Schema.DisplayType fieldType = Schema.DisplayType.valueOf(field.fieldDataType);
            map_apiNameToDisplayType.put(field.fieldApiName, fieldType);
            map_apiNameToCharCount.put(field.fieldApiName, new CustomCharWrapper(field.fromChar, field.toChar));
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
                if(record.get(fieldApiName) != null) {                    
                    if (map_apiNameToDisplayType.get(fieldApiName) == Schema.DisplayType.Phone) {
                        Integer redactionFromChar = map_apiNameToCharCount.get(fieldApiName).fromChar;
                        Integer redactionToChar = map_apiNameToCharCount.get(fieldApiName).toChar;
                        String fieldValue = (String)record.get(fieldApiName);
                        String redactedValue = DataMaskHelper.generateRedactedValue(fieldValue, redactionFromChar, redactionToChar) == null? '' : DataMaskHelper.generateRedactedValue(fieldValue, redactionFromChar, redactionToChar);
                        if(redactedValue != '') {
                            record.put(fieldApiName, redactedValue);
                        }
                    }
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
        if (payload != null && !payload.isEmpty()) {
            payload.remove(0);
            if (!payload.isEmpty()) {
                Database.executeBatch(new Batch_RedactObjectRecordDetails(payload));
            }
        }
    }


    public class CustomCharWrapper {
        public Integer fromChar;
        public Integer toChar;

        public CustomCharWrapper(Integer fromChar, Integer toChar) {
            this.fromChar = fromChar;
            this.toChar = toChar;
        }
    }
}
