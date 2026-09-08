@IsTest
public class EmailValidatorTest {
    @IsTest
    static void testValidEmails() {
        // List of valid email addresses
        List<String> validEmails = new List<String>{
            'test@example.com',
            'user.name+tag+sorting@example.com',
            'user.name@example.co.uk',
            'user-name@example.co',
            'user_name@example.io'
        };
        
        // Assert that all valid emails pass validation
        for (String email : validEmails) {
            System.assert(EmailValidator.isValidEmail(email), 'Email should be valid: ' + email);
        }
    }

    @IsTest
    static void testInvalidEmails() {
        // List of invalid email addresses
        List<String> invalidEmails = new List<String>{
            'plainaddress',
            '@missingusername.com',
            'username@.com.my',
            'username@.example.com',
            'username@example..com',
            'username@example..com',
            'username@example,com',
            'username@example.com.',
            'info@exclusiveandprivate'
        };
        
        // Assert that all invalid emails fail validation
        for (String email : invalidEmails) {
            System.assert(!EmailValidator.isValidEmail(email), 'Email should be invalid: ' + email);
        }
    }

    @IsTest
    static void testBlankAndNullEmails() {
        // Test blank email
        System.assert(!EmailValidator.isValidEmail(''), 'Blank email should be invalid');
        
        // Test null email
        System.assert(!EmailValidator.isValidEmail(null), 'Null email should be invalid');
    }
}