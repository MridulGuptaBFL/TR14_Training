trigger AccountTrigger on Account (before delete) {
    AccountTriggerHandler.handleBeforeDelete(Trigger.oldMap);
}