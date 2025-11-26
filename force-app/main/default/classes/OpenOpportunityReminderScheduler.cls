/**
 * @author Mridul Krishna Gupta
 * @email mridul.gupta@theblueflamelabs.com
 * @created date 11-11-2025
 * @desc Scheduler class to execute OpenOpportunityReminderBatch on a nightly basis.
 *       Implements Schedulable interface to allow batch processing to run at scheduled intervals.
 *       Executes the batch with a batch size of 200 records per chunk.
 *       
 *       To schedule this class to run nightly at 10 PM (22:00):
 *       System.schedule('Nightly Opportunity Reminder', '0 0 22 * * ?', new OpenOpportunityReminderScheduler());
 */
public class OpenOpportunityReminderScheduler implements Schedulable {
    
    /**
     * @description This method is invoked by the Salesforce scheduler at the scheduled time.
     *              It instantiates the OpenOpportunityReminderBatch class and executes it
     *              with a batch size of 200 records. This allows the batch to process open
     *              opportunities in manageable chunks while respecting governor limits.
     * @author Mridul Krishna Gupta
     * @param  sc    :   SchedulableContext - context of the scheduled job execution
     * @return void
    */
    public void execute(SchedulableContext sc) {
        OpenOpportunityReminderBatch batch = new OpenOpportunityReminderBatch();
        Database.executeBatch(batch, 200);
    }
}

/*
 * SCHEDULING INSTRUCTIONS:
 * =======================
 * To schedule this class to run nightly at 11:59 PM (23:59):
 * 
 * System.schedule('Nightly Opportunity Reminder', '59 59 23 * * ?', new OpenOpportunityReminderScheduler());
 * 
 * Cron Expression Breakdown: '0 0 23 * * ?'
 * - 59    : Seconds (0-59)
 * - 59    : Minutes (0-59)
 * - 23    : Hours (0-23) - 11 PM in 24-hour format
 * - *     : Day of Month (1-31)
 * - *     : Month (1-12)
 * - ?     : Day of Week (1-7, where 1=Sunday)
 * =======================
 */