trigger OpportunityTrigger on Opportunity (after insert) {
 
    if (Trigger.isAfter && Trigger.isInsert) { 
        OpportunityTriggerHandler.afterInsert(Trigger.new);
    }
}