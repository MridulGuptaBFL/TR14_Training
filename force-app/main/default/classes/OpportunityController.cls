/**
* @File Name : OpportunityController.cls
* @Description :
* @Author : Mridul Gupta
* @Last Modified By :
* @Last Modified On : October 12, 2025
* @Modification Log :
*==============================================================================
* Ver | Date | Author | Modification
*==============================================================================
* 1.0 | October 12, 2025 | Mridul Gupta  | Initial Version
**/
//public class AuraHandledException extends Exception {}

public with sharing class OpportunityController {
    @AuraEnabled
    public static Opportunity createOpp(String name, Decimal amount, String stage) {
        if (String.isBlank(name)) {
            throw new AuraHandledException('Opportunity Name cannot be empty.');
        }
        if (amount == null || amount <= 0) {
            throw new AuraHandledException('Amount must be greater than zero.');
        }
        
        Account acc = [SELECT Id, Name FROM Account LIMIT 1]; // pick any Account
        
        
        Opportunity opp = new Opportunity(
            Name = name,
        StageName = stage,
        CloseDate = Date.today().addDays(30),
        Amount = amount,
        AccountId = acc.Id
            );
        insert opp;
        return [SELECT Id, Name, StageName, Amount, AccountId, Account.Name FROM Opportunity WHERE Id = :opp.Id];
    }
}