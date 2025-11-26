public class OpenOpportunityReminderScheduler implements Schedulable {
    
    public void execute(SchedulableContext sc) {
        OpenOpportunityReminderBatch batch = new OpenOpportunityReminderBatch();
        Database.executeBatch(batch, 200);
    }
}