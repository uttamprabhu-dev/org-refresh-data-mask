@isTest
private class DataMaskHelperTest {

    @isTest
    static void testGenerateRandomString_correctLength() {
        String result = DataMaskHelper.generateRandomString(10, DataMaskHelper.ALPHANUMERIC);
        Assert.areEqual(10, result.length(), 'Should return a string of the requested length');
    }

    @isTest
    static void testGenerateRandomString_zeroLength() {
        String result = DataMaskHelper.generateRandomString(0, DataMaskHelper.ALPHANUMERIC);
        Assert.areEqual(0, result.length(), 'Zero-length request should return an empty string');
    }

    @isTest
    static void testGenerateRandomString_charsFromCharset() {
        String result = DataMaskHelper.generateRandomString(30, DataMaskHelper.NUMERIC);
        for (Integer i = 0; i < result.length(); i++) {
            Assert.isTrue(
                DataMaskHelper.NUMERIC.contains(result.substring(i, i + 1)),
                'Every character should come from the supplied charset'
            );
        }
    }

    @isTest
    static void testGenerateRandomDigits_allNumeric() {
        String digits = DataMaskHelper.generateRandomDigits(12);
        Assert.areEqual(12, digits.length(), 'Should return the requested number of digits');
        for (Integer i = 0; i < digits.length(); i++) {
            Assert.isTrue(
                DataMaskHelper.NUMERIC.contains(digits.substring(i, i + 1)),
                'Every character should be a digit'
            );
        }
    }

    @isTest
    static void testGenerateRandomPhoneNumber_format() {
        String phone = DataMaskHelper.generate_randomPhoneNumber();
        Assert.areEqual(14, phone.length(), 'Phone should be 14 characters: (XXX) XXX-XXXX');
        Assert.areEqual('(', phone.substring(0, 1), 'Phone should open with (');
        Assert.areEqual(')', phone.substring(4, 5), 'Phone should have ) at position 4');
        Assert.areEqual(' ', phone.substring(5, 6), 'Phone should have a space at position 5');
        Assert.areEqual('-', phone.substring(9, 10), 'Phone should have - at position 9');
    }

    @isTest
    static void testGenerateRandomEmail_format() {
        String email = DataMaskHelper.generate_randomEmail();
        Assert.isTrue(email.contains('@'), 'Email should contain @');
        Assert.isTrue(email.contains('.'), 'Email should contain a dot in the domain');
        Assert.isTrue(email.indexOf('@') > 0, 'Email should have a non-empty username before @');
    }

    @isTest
    static void testGenerateRandomUrl_startsWithProtocol() {
        String url = DataMaskHelper.generate_randomUrl();
        Assert.isTrue(url.startsWith('http'), 'URL should start with http or https');
        Assert.isTrue(url.contains('://'), 'URL should contain ://');
    }

    @isTest
    static void testGenerateCreditCardNumber_format() {
        String cc = DataMaskHelper.generate_randomCreditCardNumber();
        Assert.areEqual(19, cc.length(), 'Credit card should be 19 chars: XXXX-XXXX-XXXX-XXXX');
        Assert.areEqual('-', cc.substring(4, 5),  'First dash should be at position 4');
        Assert.areEqual('-', cc.substring(9, 10), 'Second dash should be at position 9');
        Assert.areEqual('-', cc.substring(14, 15), 'Third dash should be at position 14');
    }

    @isTest
    static void testGenerateAccountNumber_format() {
        String accNum = DataMaskHelper.generate_randomAccountNumber();
        Assert.isTrue(accNum.startsWith('ACC-'), 'Account number should start with ACC-');
        Assert.areEqual(12, accNum.length(), 'Account number should be 12 chars: ACC- + 8 uppercase alphanumeric');
    }

    @isTest
    static void testGenerateRandomTitleCaseName_format() {
        String name = DataMaskHelper.generateRandomTitleCaseName(5, 7);
        List<String> parts = name.split(' ');
        Assert.areEqual(2, parts.size(), 'Name should have exactly two parts separated by a space');
        Assert.areEqual(5, parts[0].length(), 'First name should have the requested length');
        Assert.areEqual(7, parts[1].length(), 'Last name should have the requested length');
        Assert.areEqual(
            parts[0].substring(0, 1).toUpperCase(),
            parts[0].substring(0, 1),
            'First name should start with an uppercase letter'
        );
        Assert.areEqual(
            parts[1].substring(0, 1).toUpperCase(),
            parts[1].substring(0, 1),
            'Last name should start with an uppercase letter'
        );
    }

    @isTest
    static void testGenerateRandomTitleCaseName_restIsLowercase() {
        String name = DataMaskHelper.generateRandomTitleCaseName(6, 6);
        List<String> parts = name.split(' ');
        Assert.areEqual(
            parts[0].substring(1).toLowerCase(),
            parts[0].substring(1),
            'Rest of first name should be lowercase'
        );
        Assert.areEqual(
            parts[1].substring(1).toLowerCase(),
            parts[1].substring(1),
            'Rest of last name should be lowercase'
        );
    }
}