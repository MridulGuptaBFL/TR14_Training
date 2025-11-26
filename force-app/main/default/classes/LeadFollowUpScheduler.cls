/**
* @File Name : LeadFollowUpScheduler.cls
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

global with sharing class LeadFollowUpScheduler implements Schedulable {
    global void execute(SchedulableContext sc) {
        System.enqueueJob(new CollectWorkingLeadsQueueable());
    }
}