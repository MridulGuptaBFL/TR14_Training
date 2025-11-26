global with sharing class ClosedWonOpportunityScheduler implements Schedulable {
 
 global void execute(SchedulableContext sc) {
  // default runDate = Date.today() in batch, but scheduler runs at midnight - Date.today() represents that date in org timezone
  Database.executeBatch(new ClosedWonOpportunityBatch(), 200); // batch size 200 (accounts per execute)
 }

}