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
                        String phoneRedactedValue = DataMaskHelper.generateRedactedPhoneValue(fieldValue, redactionFromChar, redactionToChar);
                        if(phoneRedactedValue != '' || phoneRedactedValue != null) {
                            record.put(fieldApiName, phoneRedactedValue);
                        }
                    } else if (map_apiNameToDisplayType.get(fieldApiName) == Schema.DisplayType.Email) {
                        System.debug('Email type field');
                        Integer redactionFromChar = map_apiNameToCharCount.get(fieldApiName).fromChar;
                        Integer redactionToChar = map_apiNameToCharCount.get(fieldApiName).toChar;
                        String fieldValue = (String)record.get(fieldApiName);
                        String emailRedactedValue = DataMaskHelper.generateRedactedEmailValue(fieldValue, redactionFromChar, redactionToChar);
                        if(emailRedactedValue != '' || emailRedactedValue != null) {
                            record.put(fieldApiName, emailRedactedValue);
                        }
                    }
                }
            }
            list_recordsToUpdate.add(record);
        }
        // 5. Single DML statement for all records
        if (!list_recordsToUpdate.isEmpty()) {
            Database.DMLOptions dmo = new Database.DMLOptions();
            dmo.DuplicateRuleHeader.allowSave = true;
            dmo.optAllOrNone = false;
            Database.SaveResult[] list_updatedRecords = Database.update(list_recordsToUpdate, dmo);
            for (Integer i = 0; i < list_updatedRecords.size(); i++) {
                Database.SaveResult sr = list_updatedRecords[i];
                
                if (sr.isSuccess()) {
                    // --- SUCCESS SCENARIO ---
                    // sr.getId() gives you the ID of the successfully processed record
                    System.debug('Success: Record processed successfully. ID: ' + sr.getId());
                    
                } else {
                    // --- FAILURE SCENARIO ---
                    // If you need to know WHICH record failed from your original list:
                    SObject failedRecord = list_recordsToUpdate.get(i); 
                    System.debug('Failure: Record failed to save. Source Record Name: ' + failedRecord);
                    
                    for(Database.Error err : sr.getErrors()) {
                        System.debug('Error Status Code: ' + err.getStatusCode());
                        System.debug('Error Message: ' + err.getMessage());
                        System.debug('Fields that caused the error: ' + err.getFields());
                    }
                }
            }
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
