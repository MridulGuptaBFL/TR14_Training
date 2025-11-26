/**
* @File Name : CreateTaskForLeadsQueueable.cls
* @Description :
* @Author :
* @Last Modified By :
* @Last Modified On : October 24, 2025
* @Modification Log :
*==============================================================================
* Ver | Date | Author | Modification
*==============================================================================
* 1.0 | October 24, 2025 |   | Initial Version
**/

public with sharing class CreateTaskForLeadsQueueable implements Queueable {
    private List<Id> leadIds;
    public CreateTaskForLeadsQueueable(List<Id> leadIds) {
        this.leadIds = leadIds;
    }
    
    public void execute(QueueableContext context) {
        if (leadIds == null || leadIds.isEmpty()) return;
        List<Lead> leads = [SELECT Id, OwnerId FROM Lead WHERE Id IN :leadIds];
        List<Task> tasks = new List<Task>();
        for (Lead l : leads) {
            tasks.add(new Task(OwnerId = l.OwnerId, WhoId = l.Id, Subject = 'Follow-up on Lead', Priority = 'Normal', Status = 'Not Started', ActivityDate = Date.today()));
        }
        if (!tasks.isEmpty()) insert tasks;
    }
}