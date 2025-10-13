public class CaseTriggerHandler {

    public static void updateProjectHours(Set<Id> projectIds) {
        // Aggregate Billable and Non-Billable hours from all related tasks
        Map<Id, AggregateResult> projectIdVsTotalHoursMap = new Map<Id, AggregateResult>();
    
        for (AggregateResult aggregateResultIterator : [
            SELECT Project__c projectId,
                SUM(Billable_Hours__c) sumBillable,
                SUM(Non_Billable_Hours__c) sumNonBillable
            FROM Case
            WHERE Project__c IN :projectIds
            GROUP BY Project__c
        ]) {
            projectIdVsTotalHoursMap.put((Id) aggregateResultIterator.get('projectId'), aggregateResultIterator);
        }
    
        // Prepare Projects for update
        List<Project__c> projectsToUpdateList = new List<Project__c>();
    
        for (Id projectId : projectIds) {
            Project__c proj = new Project__c(Id = projectId);
            if (projectIdVsTotalHoursMap.containsKey(projectId)) {
                proj.Billable_Hours__c = (Decimal) projectIdVsTotalHoursMap.get(projectId).get('sumBillable');
                proj.Non_Billable_Hours__c = (Decimal) projectIdVsTotalHoursMap.get(projectId).get('sumNonBillable');
            } else {
                // No tasks — set both totals to zero
                proj.Billable_Hours__c = 0;
                proj.Non_Billable_Hours__c = 0;
            }
            projectsToUpdateList.add(proj);
        }
    
        update projectsToUpdateList;
    }
 

}