/**
* @File Name : CollectWorkingLeadsQueueable.cls
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

public with sharing class CollectWorkingLeadsQueueable implements Queueable {
  public void execute(QueueableContext context) {
    List<Lead> leads = [SELECT Id, OwnerId FROM Lead WHERE Status = 'Working - Contacted'];
    if (leads.isEmpty()) {
      return;
    }
    // Pass only necessary fields to next job to reduce serialized payload
    System.enqueueJob(new CreateTaskForLeadsQueueable(new List<Id>(new Map<Id, Lead>(leads).keySet())));
  }
}