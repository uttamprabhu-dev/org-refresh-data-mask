public with sharing class DataMaskHelper {

    public static final String ALPHA = 'ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz';
    public static final String NUMERIC = '0123456789';
    public static final String ALPHANUMERIC = ALPHA + NUMERIC;

    public static final String PHONE_ALLOWED_SPCL_CHARS = '!#$%&\'\'*+-/=?^_`{|}~.';
    public static final String EMAIL_ALLOWED_SPCL_CHARS = '!#$%&\'\'*+-/=?^_`{|}~.';

    public DataMaskHelper() {
    }

    /**
     * Generates a random phone number in format (XXX) XXX-XXXX
     */
    public static String generate_randomPhoneNumber() {
        String digits = generateRandomDigits(8);

        String ch1 = getRandomPhoneSpecialChar();
        String ch2 = getRandomPhoneSpecialChar();

        // Insert 2 special characters into the 10-character string
        return digits.substring(0, 4)
            + ch1
            + digits.substring(4, 7)
            + ch2
            + digits.substring(7);
    }

    private static String getRandomPhoneSpecialChar() {
        Integer index = Math.mod(Math.abs(Crypto.getRandomInteger()), PHONE_ALLOWED_SPCL_CHARS.length());
        return PHONE_ALLOWED_SPCL_CHARS.substring(index, index + 1);
    }

    /**
     * Generates a random email address
     */
    public static String generate_randomEmail() {
        String username = generateRandomString(8, ALPHANUMERIC);
        String[] domains = new String[]{ 'example.net', 'example.org', 'example.com' };
        String domain = domains[Math.mod(Math.abs((Integer)(Crypto.getRandomLong())), domains.size())];
        return username + '@' + domain;
    }

    /**
     * Generates a random URL
     */
    public static String generate_randomUrl() {
        String[] protocols = new String[]{'https://', 'http://'};
        String[] domainPrefixes = new String[]{'www.', ''};
        String[] domains = new String[]{'example', 'test', 'sample', 'demo', 'site'};
        String[] tlds = new String[]{'.com', '.org', '.net', '.io'};
        String[] paths = new String[]{'/home', '/about', '/contact', '/api', '/data', ''};

        String protocol = protocols[Math.mod(Math.abs((Integer)(Crypto.getRandomLong())), protocols.size())];
        String prefix = domainPrefixes[Math.mod(Math.abs((Integer)(Crypto.getRandomLong())), domainPrefixes.size())];
        String domain = domains[Math.mod(Math.abs((Integer)(Crypto.getRandomLong())), domains.size())];
        String tld = tlds[Math.mod(Math.abs((Integer)(Crypto.getRandomLong())), tlds.size())];
        String path = paths[Math.mod(Math.abs((Integer)(Crypto.getRandomLong())), paths.size())];

        return protocol + prefix + domain + tld + path;
    }

    /**
     * Generates a random credit card number (16 digits, grouped as XXXX-XXXX-XXXX-XXXX)
     */
    public static String generate_randomCreditCardNumber() {
        String digits = generateRandomDigits(16);
        return digits.substring(0, 4) + '-' +
               digits.substring(4, 8) + '-' +
               digits.substring(8, 12) + '-' +
               digits.substring(12, 16);
    }

    /**
     * Generates a random account number (10 alphanumeric characters)
     */
    public static String generate_randomAccountNumber() {
        return 'ACC-' + generateRandomString(8, ALPHANUMERIC).toUpperCase();
    }

    /**
     * Helper: Generate N random digits
     */
    public static String generateRandomDigits(Integer count) {
        return generateRandomString(count, NUMERIC);
    }

    /**
     * Helper: Generate a random string of specified length from given character set
     */
    public static String generateRandomString(Integer length, String charSet) {
        String result = '';
        Integer charsetLength = charSet.length();

        for (Integer i = 0; i < length; i++) {
            Integer randomIndex = Math.mod(Math.abs((Integer)(Crypto.getRandomLong())), charsetLength);
            result += charSet.substring(randomIndex, randomIndex + 1);
        }

        return result;
    }

    /**
     * Helper: Generate a random title case name of specified length from given character set
     */
    public static String generateRandomTitleCaseName(Integer firstLen, Integer lastLen) {
        // Generate raw random strings for first and last names
        String first = generateRandomString(firstLen, ALPHA);
        String last = generateRandomString(lastLen, ALPHA);

        // Format to Title Case: (First Letter Upper) + (Rest Lower)
        String formattedFirst = first.substring(0, 1).toUpperCase() + first.substring(1).toLowerCase();
        String formattedLast = last.substring(0, 1).toUpperCase() + last.substring(1).toLowerCase();

        return formattedFirst + ' ' + formattedLast;
    }

    /**                                                                                                                                                      
    * Redacts alphanumeric characters in a phone field value from the specified                                                                             
    * 1-based character range, replacing them with asterisks while preserving                                                                               
    * special characters (e.g., dashes, parentheses, spaces) in their original positions.                                                                   
    * The fromChar and toChar values refer to alphanumeric character positions only,                                                                        
    * excluding special characters from the count.                                                                                                          
    * Returns null if the original value is null, empty, already redacted (contains '*'),                                                                   
    * or if the specified alphanumeric range is out of bounds.                                                                                              
    */ 
    public static String generateRedactedPhoneValue(String originalValue, Integer intFromChar, Integer intToChar) {
        if (String.isBlank(originalValue) || originalValue.contains('*') || intFromChar == null || intToChar == null) {
            return null;
        }

        Integer intFromIndex = intFromChar - 1;
        Integer intToIndex = intToChar - 1;

        if(intFromIndex < 0 || intToIndex < 0 || intFromIndex > intToIndex || intFromIndex >= originalValue.length() || intToIndex >= originalValue.length()) {
            return null;
        }

        // Build a list of only the alphanumeric character positions
        String alphaNumericChars = ALPHANUMERIC + ALPHANUMERIC.toLowerCase() + PHONE_ALLOWED_SPCL_CHARS;
        List<Integer> list_intCharPositions = new List<Integer>();
        for (Integer i = 0; i < originalValue.length(); i++) {
            if (alphaNumericChars.contains(originalValue.substring(i, i + 1))) {
                list_intCharPositions.add(i);
            }
        }

        // Check bounds against the count of alphanumeric characters only
        if (list_intCharPositions.isEmpty() || intFromIndex >= list_intCharPositions.size() || intToIndex >= list_intCharPositions.size()) {
            return null;
        }

        // Build result, preserving special characters
        List<String> resultChars = new List<String>();
        for (Integer i = 0; i < originalValue.length(); i++) {
            resultChars.add(originalValue.substring(i, i + 1));
        }

        // Replace chars in the specified alphanumeric range with asterisks
        for (Integer pos = intFromIndex; pos <= intToIndex; pos++) {
            Integer originalPos = list_intCharPositions[pos];
            resultChars[originalPos] = '*';
        }

        return String.join(resultChars, '');
    }

    public static String generateRedactedEmailValue(String originalValue, Integer intFromChar, Integer intToChar) {
        if (String.isBlank(originalValue) || originalValue.contains('*') || intFromChar == null || intToChar == null) {
            return null;
        }

        Integer intFromIndex = intFromChar - 1;
        Integer intToIndex = intToChar - 1;

        if(intFromIndex < 0 || intToIndex < 0 || intFromIndex > intToIndex || intFromIndex >= originalValue.length() || intToIndex >= originalValue.length()) {
            return null;
        }

        // find the index of the character that appears before '@'
        Integer intLastIndex = originalValue.lastIndexOf('@') - 1;

        // check for out of bounds scenarios and return null
        if(intFromIndex > intLastIndex || intToIndex > intLastIndex) {
            return null;
        }

        // working scenarios
        // extract the chars before '@' and replace the chars from intFromIndex to intToIndex with null
        // Build result as list of characters
        List<String> resultChars = new List<String>();
        for (Integer i = 0; i <= intLastIndex; i++) {
            resultChars.add(originalValue.substring(i, i + 1));
        }                                                      

        // Replace chars in range with asterisks
        for (Integer pos = intFromIndex; pos <= intToIndex; pos++) {
            resultChars[pos] = '*';
        }
        String redactedSection = String.join(resultChars, '');
        return redactedSection + originalValue.substring(intLastIndex + 1);
    }
    
}