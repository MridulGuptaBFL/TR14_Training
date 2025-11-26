/**
* @File Name : PubsubAccountController.cls
* @Description :
* @Author :
* @Last Modified By :
* @Last Modified On : October 23, 2025
* @Modification Log :
*==============================================================================
* Ver | Date | Author | Modification
*==============================================================================
* 1.0 | October 23, 2025 |   | Initial Version
**/

public with sharing class PubsubAccountController {
    //pubsub regards
   
 
    //  Get list of Accounts
    @AuraEnabled(cacheable=true)
    public static List<Account> getAccounts() {
        return [SELECT Id, Name FROM Account LIMIT 20];
    }
 
    // Get list of Contacts related to selected Account
    @AuraEnabled(cacheable=true)
    public static List<Contact> getContacts(Id accountId) {
        if (accountId == null) return new List<Contact>();
        return [
            SELECT Id, FirstName, LastName, Email, MailingAddress
            FROM Contact
            WHERE AccountId = :accountId
        ];
    }
 
}