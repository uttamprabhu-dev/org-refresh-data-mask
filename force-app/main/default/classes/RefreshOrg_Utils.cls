public with sharing class RefreshOrg_Utils {

    public static List<String> list_fieldLabelKeywords = new List<String>{
    };

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
        List<String> labelWords = field.getLabel().toLowerCase().split('[^a-z0-9]+');
        Set<String> labelWordSet = new Set<String>(labelWords);
        for (String keyword : list_fieldLabelKeywords) {
            if (labelWordSet.contains(keyword.toLowerCase())) return true;
        }
        return false;
    }
}