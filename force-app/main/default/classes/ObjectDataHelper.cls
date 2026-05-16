public with sharing class ObjectDataHelper {
    public class SObjectWrapper implements Comparable {
        @AuraEnabled public String apiName;
        @AuraEnabled public String label;

        public SObjectWrapper(String apiName, String label) {
            this.apiName = apiName;
            this.label  = label;
        }

        public Integer compareTo(Object other) {
            SObjectWrapper o = (SObjectWrapper) other;
            return this.label.compareTo(o.label);
        }
    }

    @AuraEnabled(cacheable=true)
    public static List<SObjectWrapper> getNonSetupObjects(String searchTerm) {
        List<SObjectWrapper> result = new List<SObjectWrapper>();

        if (String.isBlank(searchTerm)) {
            return result;
        }

        String lowerSearch = searchTerm.toLowerCase();
        Map<String, Schema.SObjectType> globalDescribe = Schema.getGlobalDescribe();

        for (String apiName : globalDescribe.keySet()) {
            Schema.DescribeSObjectResult describe =
                globalDescribe.get(apiName).getDescribe();

            if (
                !describe.isCustomSetting()  &&
                describe.isQueryable()       &&
                !describe.isDeprecatedAndHidden()
            ) {
                String objLabel   = describe.getLabel().toLowerCase();
                String objApiName = describe.getName().toLowerCase();
                if (objLabel.contains(lowerSearch) || objApiName.contains(lowerSearch)) {
                    result.add(new SObjectWrapper(describe.getName(), describe.getLabel()));
                }
            }
        }

        result.sort();
        System.debug(result);
        return result;
    }

    public class FieldWrapper implements Comparable {
        @AuraEnabled public String apiName;
        @AuraEnabled public String label;
        @AuraEnabled public String dataType;

        public FieldWrapper(String apiName, String label, String dataType) {
            this.apiName  = apiName;
            this.label    = label;
            this.dataType = dataType;
        }

        public Integer compareTo(Object other) {
            FieldWrapper o = (FieldWrapper) other;
            return this.label.compareTo(o.label);
        }
    }

    @AuraEnabled
    public static List<FieldWrapper> getObjectFields(String objectApiName) {
        try {
            List<FieldWrapper> result = new List<FieldWrapper>();

            Schema.SObjectType sObjectType = Schema.getGlobalDescribe().get(objectApiName);
            if (sObjectType == null) {
                AuraHandledException e = new AuraHandledException(
                    'Invalid object API name: ' + objectApiName
                );
                e.setMessage('Invalid object API name: ' + objectApiName); // ← key fix
                throw e;
            }

            Map<String, Schema.SObjectField> fieldMap =
                sObjectType.getDescribe().fields.getMap();

            for (String fieldApiName : fieldMap.keySet()) {
                Schema.DescribeFieldResult field =
                    fieldMap.get(fieldApiName).getDescribe();
                Boolean blnIsSensitive = RefreshOrg_Utils.isSensitiveField(field);
                if (field.isAccessible() && blnIsSensitive) {
                    result.add(new FieldWrapper(
                        field.getName(),
                        field.getLabel(),
                        String.valueOf(field.getType())
                    ));
                }
            }

            result.sort();
            return result;

        } catch (AuraHandledException e) {
            throw e;
        } catch (Exception e) {
            AuraHandledException ahe = new AuraHandledException(e.getMessage());
            ahe.setMessage(e.getMessage());
            throw ahe;
        }
    }
}