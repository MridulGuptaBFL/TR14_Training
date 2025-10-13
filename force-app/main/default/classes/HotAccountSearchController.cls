public with sharing class HotAccountSearchController {
    @AuraEnabled(cacheable=true)
    public static List<Account> searchAccounts(String accountName) {
        return [SELECT Id, Name FROM Account WHERE Name LIKE :('%' + accountName + '%') AND Rating = 'Hot' LIMIT 10];
    }
 
    @AuraEnabled(cacheable=true)
    public static Account getAccountDetails(Id accountId) {
        return [SELECT Id, Name, SLA__c, Rating, Website FROM Account WHERE Id = :accountId LIMIT 1];
    }
 
    @AuraEnabled(cacheable=true)
    public static List<Opportunity> getOpenOpportunities(Id accountId) {
        return [
            SELECT Id, Name, Owner.Email
            FROM Opportunity
            WHERE AccountId = :accountId AND IsClosed = false
        ];
    }
}