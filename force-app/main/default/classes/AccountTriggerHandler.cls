public with sharing class AccountTriggerHandler {
    public static void handleBeforeDelete(Map<Id, Account> oldMap) {
        Set<Id> accountIds = oldMap.keySet();//extraction of Ids are easier through map
        Map<Id, Integer> accountIdVsContactCounts = new Map<Id, Integer>();
        for (AggregateResult ar : [
            SELECT AccountId, COUNT(Id) cnt 
            FROM Contact 
            WHERE AccountId IN :accountIds 
            GROUP BY AccountId
        ]) {//stores the acount Id vs. number of associated contacts
            accountIdVsContactCounts.put((Id)ar.get('AccountId'), (Integer)ar.get('cnt'));
        }
        String errorMsg = Label.Account_Error_Apex;// "Cannot delete Account with existing Contacts."
        for (Id accId : accountIds) {
            if (accountIdVsContactCounts.containsKey(accId) && accountIdVsContactCounts.get(accId) > 0) {
                oldMap.get(accId).addError(errorMsg);
            }
        }
    }
}