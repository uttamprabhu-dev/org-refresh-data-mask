public with sharing class RefreshOrg_Utils {
    public static List<String> getFieldTypes() {
        List<String> displayTypes = new List<String>();

        for (Schema.DisplayType dt : Schema.DisplayType.values()) {
            displayTypes.add(String.valueOf(dt));
        }

        return displayTypes;
    }

    public static Boolean isEditableField(Schema.DescribeFieldResult field) {
        if (field.isCalculated())                                      return false; // Formula
        if (field.isAutoNumber())                                      return false; // Auto Number
        if (field.getType() == Schema.DisplayType.REFERENCE)           return false; // Lookup
        if (!field.isUpdateable() && !field.isCreateable() 
            && !field.isCalculated() && !field.isAutoNumber())         return false; // Roll-up Summary

        return true;
    }

    public static Boolean isSensitiveField(Schema.DescribeFieldResult field) {
        if(field.getType() == Schema.DisplayType.EMAIL) return true;
        if(field.getType() == Schema.DisplayType.PHONE) return true;
        return false;
    }
}