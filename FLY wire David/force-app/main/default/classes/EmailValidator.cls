public class EmailValidator {
    // Regular expression for validating email addresses
    // private static final String EMAIL_REGEX = '^[a-zA-Z0-9.!#$%&\'*+/=?^_`{|}~-]+@[a-zA-Z0-9-]+(?:\\.[a-zA-Z0-9-]+)*$';
    private static final String EMAIL_REGEX = '^[a-zA-Z0-9.!#$%&\'*+/=?^_`{|}~-]+@[a-zA-Z0-9-]+(?:\\.[a-zA-Z0-9-]+)+$';

    // Method to validate email address
    public static Boolean isValidEmail(String email) {
        if (String.isBlank(email)) {
            return false;
        }
        Pattern emailPattern = Pattern.compile(EMAIL_REGEX);
        Matcher emailMatcher = emailPattern.matcher(email);
        return emailMatcher.matches();
    }
}