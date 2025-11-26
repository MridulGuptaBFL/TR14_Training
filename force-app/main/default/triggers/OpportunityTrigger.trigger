trigger OpportunityTrigger on Opportunity (after insert, after update, after delete, after undelete) { 

    Set<Id> accountIds = new Set<Id>(); 
 
    if (Trigger.isAfter && (Trigger.isInsert || Trigger.isUpdate || Trigger.isUndelete)) { 
        for (Opportunity opp : Trigger.new) { 
            if (opp.AccountId != null) { 
                accountIds.add(opp.AccountId); 
            } 
        } 
    } 
 
    if (Trigger.isAfter && Trigger.isDelete) { 
        for (Opportunity opp : Trigger.old) { 
            if (opp.AccountId != null) { 
                accountIds.add(opp.AccountId); 
            } 
        } 
    } 
 
    if (!accountIds.isEmpty()) { 
        OpportunityTriggerHandler.updateAccountPointsAsync(accountIds); 
    } 
}