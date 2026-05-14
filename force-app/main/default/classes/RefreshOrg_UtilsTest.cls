@isTest
private class RefreshOrg_UtilsTest {

    // ── getFieldTypes ─────────────────────────────────────────────────────────

    @isTest
    static void testGetFieldTypes_returnsNonEmptyList() {
        List<String> types = RefreshOrg_Utils.getFieldTypes();
        Assert.isNotNull(types, 'Result should not be null');
        Assert.isTrue(types.size() > 0, 'Result should contain at least one display type');
    }

    @isTest
    static void testGetFieldTypes_matchesSchemaDisplayTypeCount() {
        List<String> types = RefreshOrg_Utils.getFieldTypes();
        Assert.areEqual(
            Schema.DisplayType.values().size(),
            types.size(),
            'Returned list size should match Schema.DisplayType.values() count'
        );
    }

    @isTest
    static void testGetFieldTypes_containsKnownTypes() {
        List<String> types = RefreshOrg_Utils.getFieldTypes();
        Set<String> typeSet = new Set<String>(types);
        // Use String.valueOf() on the enum constants so the assertion is self-consistent
        // with whatever runtime representation getFieldTypes() produces
        Assert.isTrue(typeSet.contains(String.valueOf(Schema.DisplayType.Email)),   'Result should include Email display type');
        Assert.isTrue(typeSet.contains(String.valueOf(Schema.DisplayType.Phone)),   'Result should include Phone display type');
        Assert.isTrue(typeSet.contains(String.valueOf(Schema.DisplayType.Boolean)), 'Result should include Boolean display type');
    }

    // ── isEditableField ───────────────────────────────────────────────────────

    @isTest
    static void testIsEditableField_regularTextField_returnsTrue() {
        // Account.Name: updateable, createable — editable
        Schema.DescribeFieldResult field = Schema.SObjectType.Account.fields.Name.getSObjectField().getDescribe();
        Assert.isTrue(RefreshOrg_Utils.isEditableField(field), 'A regular text field should be editable');
    }

    @isTest
    static void testIsEditableField_emailField_returnsTrue() {
        // Contact.Email: updateable, createable — editable
        Schema.DescribeFieldResult field = Schema.SObjectType.Contact.fields.Email.getSObjectField().getDescribe();
        Assert.isTrue(RefreshOrg_Utils.isEditableField(field), 'An email field should be editable');
    }

    @isTest
    static void testIsEditableField_referenceField_returnsFalse() {
        // Contact.AccountId: REFERENCE type — not editable per business rule
        Schema.DescribeFieldResult field = Schema.SObjectType.Contact.fields.AccountId.getSObjectField().getDescribe();
        Assert.isFalse(RefreshOrg_Utils.isEditableField(field), 'A lookup/reference field should not be editable');
    }

    @isTest
    static void testIsEditableField_autoNumberField_returnsFalse() {
        // Case.CaseNumber: auto-number — not editable
        Schema.DescribeFieldResult field = Schema.SObjectType.Case.fields.CaseNumber.getSObjectField().getDescribe();
        Assert.isFalse(RefreshOrg_Utils.isEditableField(field), 'An auto-number field should not be editable');
    }

    @isTest
    static void testIsEditableField_formulaField_returnsFalse() {
        // Opportunity.IsWon: formula (derived from StageName) — not editable
        Schema.DescribeFieldResult field = Schema.SObjectType.Opportunity.fields.IsWon.getSObjectField().getDescribe();
        Assert.isFalse(RefreshOrg_Utils.isEditableField(field), 'A formula (calculated) field should not be editable');
    }

    @isTest
    static void testIsEditableField_systemReadOnlyField_returnsFalse() {
        // Account.CreatedDate: not updateable, not createable, not calculated, not auto-number
        Schema.DescribeFieldResult field = Schema.SObjectType.Account.fields.CreatedDate.getSObjectField().getDescribe();
        Assert.isFalse(RefreshOrg_Utils.isEditableField(field), 'A system read-only field should not be editable');
    }

    // ── isSensitiveField ──────────────────────────────────────────────────────

    @isTest
    static void testIsSensitiveField_emailField_returnsTrue() {
        Schema.DescribeFieldResult field = Schema.SObjectType.Contact.fields.Email.getSObjectField().getDescribe();
        Assert.isTrue(RefreshOrg_Utils.isSensitiveField(field), 'An Email field should be sensitive');
    }

    @isTest
    static void testIsSensitiveField_phoneField_returnsTrue() {
        Schema.DescribeFieldResult field = Schema.SObjectType.Contact.fields.Phone.getSObjectField().getDescribe();
        Assert.isTrue(RefreshOrg_Utils.isSensitiveField(field), 'A Phone field should be sensitive');
    }

    @isTest
    static void testIsSensitiveField_textField_returnsFalse() {
        Schema.DescribeFieldResult field = Schema.SObjectType.Account.fields.Name.getSObjectField().getDescribe();
        Assert.isFalse(RefreshOrg_Utils.isSensitiveField(field), 'A plain text field should not be sensitive');
    }

    @isTest
    static void testIsSensitiveField_dateField_returnsFalse() {
        Schema.DescribeFieldResult field = Schema.SObjectType.Opportunity.fields.CloseDate.getSObjectField().getDescribe();
        Assert.isFalse(RefreshOrg_Utils.isSensitiveField(field), 'A date field should not be sensitive');
    }

    @isTest
    static void testIsSensitiveField_referenceField_returnsFalse() {
        Schema.DescribeFieldResult field = Schema.SObjectType.Contact.fields.AccountId.getSObjectField().getDescribe();
        Assert.isFalse(RefreshOrg_Utils.isSensitiveField(field), 'A reference field should not be sensitive');
    }
}
