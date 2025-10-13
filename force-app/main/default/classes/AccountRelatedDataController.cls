public with sharing class AccountRelatedDataController {
    @AuraEnabled(cacheable=true)
    public static Map<String, List<String>> getRelatedRecords(Id accountId) {
        Map<String, List<String>> result = new Map<String, List<String>>();
 
        List<Contact> contacts = [SELECT Id, Name FROM Contact WHERE AccountId = :accountId];
        List<Opportunity> opportunities = [SELECT Id, Name FROM Opportunity WHERE AccountId = :accountId];
        List<Project__c> projects = [SELECT Id, Name FROM Project__c WHERE Client__c = :accountId];
 
        List<String> contactNames = new List<String>();
        for (Contact c : contacts) {
            contactNames.add(c.Name);
        }
        result.put('Contacts', contactNames);
 
        List<String> opportunityNames = new List<String>();
        for (Opportunity o : opportunities) {
            opportunityNames.add(o.Name);
        }
        result.put('Opportunities', opportunityNames);
 
        List<String> projectNames = new List<String>();
        for (Project__c p : projects) {
            projectNames.add(p.Name);
        }
        result.put('Projects', projectNames);
 
        return result;
    }
}