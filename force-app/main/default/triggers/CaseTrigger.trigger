trigger CaseTrigger on Case (after insert,after delete,after update,after undelete) {
Set<Id> projectIds = new Set<Id>();

// Collect all related Project Ids
if (Trigger.isInsert || Trigger.isUpdate || Trigger.isUndelete) {
    for (case pt : Trigger.new) {
        if (pt.Project__c != null) {
            projectIds.add(pt.Project__c);
        }
    }
}
 
if (Trigger.isDelete) {
    for (case pt : Trigger.old) {
        if (pt.Project__c != null) {
            projectIds.add(pt.Project__c);
        }
    }
}
 
// Delegate logic to handler
if (!projectIds.isEmpty()) {
    CaseTriggerHandler.updateProjectHours(projectIds);
    }
}