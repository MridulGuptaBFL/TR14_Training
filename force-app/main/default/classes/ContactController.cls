/**
* @File Name : ContactController.cls
* @Description :
* @Author :
* @Last Modified By :
* @Last Modified On : October 12, 2025
* @Modification Log :
*==============================================================================
* Ver | Date | Author | Modification
*==============================================================================
* 1.0 | October 12, 2025 |   | Initial Version
**/

public with sharing class ContactController {
    
    @AuraEnabled(cacheable=true)
    public static List<Contact> getContactsByAccountId(Id accountId, String searchKey) {
        if (accountId == null) return new List<Contact>();
        String key = (searchKey == null || searchKey.trim() == '') ? '%' : '%' + searchKey.trim() + '%';
        return [ SELECT Id, FirstName, LastName, Email, Phone, Title
                FROM Contact
                WHERE AccountId = :accountId
                AND (FirstName LIKE :key OR LastName LIKE :key OR Email LIKE :key)
                ORDER BY LastName ];
    }
    
    @AuraEnabled
    public static Contact createContactForAccount(Id accountId, Contact contactData) {
        contactData.AccountId = accountId;
        insert contactData;
        return contactData;
    }
    
    @AuraEnabled(cacheable=true)
    public static Account getAccountDetails(Id accountId) {
        return [ SELECT Id, Name, Phone, Website, Industry, Type
                FROM Account
                WHERE Id = :accountId
                LIMIT 1 ];
    }
    
    @AuraEnabled
    public static Account updateAccount(Account acc) {
        update acc;
        return acc;
    }
}