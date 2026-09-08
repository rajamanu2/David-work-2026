public class LegalEmailAttachmentController {
    // This variable receives the ID from the component attribute
    public Id accountId { get; set; }
    
    // This method queries the records
    public List<Contact> getRelatedContacts() {
        if (accountId == null) {
            return new List<Contact>();
        }
        
        // Query the fields you want to display in the table
        return [SELECT FirstName, LastName, Email, Title 
                FROM Contact 
                WHERE AccountId = :accountId 
                ORDER BY FirstName ASC];
    }

}