public with sharing class DataMaskHelper {

    public static final String ALPHA = 'ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz';
    public static final String NUMERIC = '0123456789';
    public static final String ALPHANUMERIC = ALPHA + NUMERIC;

    public DataMaskHelper() {
    }

    /**
     * Generates a random phone number in format (XXX) XXX-XXXX
     */
    public static String generate_randomPhoneNumber() {
        String areaCode = generateRandomDigits(3);
        String prefix = generateRandomDigits(3);
        String lineNumber = generateRandomDigits(4);
        return '(' + areaCode + ') ' + prefix + '-' + lineNumber;
    }

    /**
     * Generates a random email address
     */
    public static String generate_randomEmail() {
        String username = generateRandomString(8, ALPHANUMERIC);
        String[] domains = new String[]{'gmail.com', 'yahoo.com', 'outlook.com', 'example.com', 'test.org'};
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
}