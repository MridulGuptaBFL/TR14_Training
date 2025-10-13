/*
Question 1:

// Batch class to collect closed won opportunities and send emails
global class ClosedWonOpportunitiesBatch implements Database.Batchable<SObject>, Database.Stateful {
    // Store map of Account Id to email body content for aggregation
    Map<Id, List<String>> accountToOppLines = new Map<Id, List<String>>();
    Map<Id, Decimal> accountToTotalAmount = new Map<Id, Decimal>();
    Map<Id, String> accountEmails = new Map<Id, String>();

    // Daily date to query Closed Won opportunities for that date
    Date batchDate;

    global ClosedWonOpportunitiesBatch() {
        batchDate = Date.today().addDays(-1); // Yesterday date as batch runs at midnight
    }

    global Database.QueryLocator start(Database.BatchableContext bc) {
        // Query all closed won opportunities that changed to closed won yesterday
        String query = 'SELECT Id, Name, Amount, AccountId, Account.Email ' +
                       'FROM Opportunity ' + 
                       'WHERE StageName = \'Closed Won\' AND CloseDate = :batchDate';

        return Database.getQueryLocator(query);
    }

    global void execute(Database.BatchableContext bc, List<Opportunity> scope) {
        for (Opportunity opp : scope) {
            // Initialize list and total amount per account
            if (!accountToOppLines.containsKey(opp.AccountId)) {
                accountToOppLines.put(opp.AccountId, new List<String>());
                accountToTotalAmount.put(opp.AccountId, 0);
                accountEmails.put(opp.AccountId, opp.Account.Email);
            }
            // Add opportunity line info
            accountToOppLines.get(opp.AccountId).add(opp.Name + ' - Amount: ' + String.valueOf(opp.Amount));
            // Aggregate total amount
            accountToTotalAmount.put(opp.AccountId, accountToTotalAmount.get(opp.AccountId) + opp.Amount);
        }
    }

    global void finish(Database.BatchableContext bc) {
        // Send email for each Account with collected closed won opps details
        List<Messaging.MassEmailMessage> emails = new List<Messaging.MassEmailMessage>();

        for (Id accountId : accountToOppLines.keySet()) {
            String toEmail = accountEmails.get(accountId);
            if (toEmail == null || toEmail == '') {
                // Skip if no primary email is available
                continue;
            }
            String body = 'Closed Won Opportunities for ' + batchDate.format() + ':\n\n';
            for (String line : accountToOppLines.get(accountId)) {
                body += line + '\n';
            }
            body += '\nTotal Amount: ' + String.valueOf(accountToTotalAmount.get(accountId));

            Messaging.SingleEmailMessage mail = new Messaging.SingleEmailMessage();
            mail.setToAddresses(new String[] { toEmail });
            mail.setSubject('Daily Closed Won Opportunities Summary');
            mail.setPlainTextBody(body);
            Messaging.sendEmail(new Messaging.SingleEmailMessage[] { mail });
        }
    }
}

// Scheduled Apex class to run batch daily at midnight
global class ClosedWonOpportunitiesScheduler implements Schedulable {
    global void execute(SchedulableContext sc) {
        ClosedWonOpportunitiesBatch batch = new ClosedWonOpportunitiesBatch();
        Database.executeBatch(batch, 200);
    }
}


//Usage:
//Deploy the batch and scheduler classes.
//Schedule the batch via Salesforce UI or using the following anonymous Apex:

String cron = '0 0 0 * * ?'; // Every day at midnight
ClosedWonOpportunitiesScheduler scheduler = new ClosedWonOpportunitiesScheduler();
System.schedule('Daily Closed Won Opps Batch', cron, scheduler);
===================================================================================================================================

Question 2:
global class MonthlyWeeklySnapshotScheduler implements Schedulable {
    global void execute(SchedulableContext sc) {
        WeeklySnapshotBatch batch = new WeeklySnapshotBatch();
        Database.executeBatch(batch, 200);
    }
}

global class WeeklySnapshotBatch implements Database.Batchable<SObject> {
    global Database.QueryLocator start(Database.BatchableContext bc) {
        // Query all tasks for the current month (using previous month if this runs on 1st)
        Date today = Date.today();
        Date firstDayOfMonth = today.toStartOfMonth();
        Date lastDayOfMonth = today.toEndOfMonth();
        
        // Adjust date range to previous month if running at start of month
        if (today.day() == 1) {
            firstDayOfMonth = firstDayOfMonth.addMonths(-1);
            lastDayOfMonth = lastDayOfMonth.addMonths(-1);
        }

        String query = 'SELECT Id, ActivityDate, Estimated_Hours__c, Billable_Hours__c, Non_Billable_Hours__c ' +
                       'FROM Task ' +
                       'WHERE ActivityDate >= :firstDayOfMonth AND ActivityDate <= :lastDayOfMonth';

        return Database.getQueryLocator(query);
    }

    global void execute(Database.BatchableContext bc, List<Task> scope) {
        // Group tasks by week for aggregation
        Map<Integer, Decimal> estimatedHoursByWeek = new Map<Integer, Decimal>();
        Map<Integer, Decimal> billableHoursByWeek = new Map<Integer, Decimal>();
        Map<Integer, Decimal> nonBillableHoursByWeek = new Map<Integer, Decimal>();
        Map<Integer, Date> weekStartDateMap = new Map<Integer, Date>();
        Map<Integer, Date> weekEndDateMap = new Map<Integer, Date>();
        Date firstDayOfMonth = scope.isEmpty() ? null : scope[0].ActivityDate.toStartOfMonth();

        if (firstDayOfMonth == null) return; // No tasks

        // Calculate the week number in month for each task and aggregate hours
        for (Task t : scope) {
            Date d = t.ActivityDate;
            // Calculate the week start (Monday) for the task date
            Integer dayOffset = (d.dayOfWeek() == 1) ? -6 : 2 - d.dayOfWeek(); // Monday adjustment
            Date weekStart = d.addDays(dayOffset);
            Date weekEnd = weekStart.addDays(6);

            // Calculate week number as nth Monday from first day of month
            Integer weekNum = 1;
            Date currentMonday = firstDayOfMonth;
            while (weekStart > currentMonday.addDays(6)) {
                weekNum++;
                currentMonday = currentMonday.addDays(7);
            }

            // Initialize maps if not present
            if (!estimatedHoursByWeek.containsKey(weekNum)) {
                estimatedHoursByWeek.put(weekNum, 0);
                billableHoursByWeek.put(weekNum, 0);
                nonBillableHoursByWeek.put(weekNum, 0);
                weekStartDateMap.put(weekNum, weekStart);
                weekEndDateMap.put(weekNum, weekEnd);
            }
            // Sum hours safely with null checks
            estimatedHoursByWeek.put(weekNum, estimatedHoursByWeek.get(weekNum) + (t.Estimated_Hours__c == null ? 0 : t.Estimated_Hours__c));
            billableHoursByWeek.put(weekNum, billableHoursByWeek.get(weekNum) + (t.Billable_Hours__c == null ? 0 : t.Billable_Hours__c));
            nonBillableHoursByWeek.put(weekNum, nonBillableHoursByWeek.get(weekNum) + (t.Non_Billable_Hours__c == null ? 0 : t.Non_Billable_Hours__c));
        }

        // Create or update WeeklySnapshot records
        List<WeeklySnapshot__c> snapshotsToInsert = new List<WeeklySnapshot__c>();
        String monthName = firstDayOfMonth.format('MMMM');
        Integer yearVal = firstDayOfMonth.year();

        for (Integer w : estimatedHoursByWeek.keySet()) {
            WeeklySnapshot__c ws = new WeeklySnapshot__c();
            ws.Name = 'WS-' + monthName + '-W' + w;
            ws.Week_Start_Date__c = weekStartDateMap.get(w);
            ws.Week_End_Date__c = weekEndDateMap.get(w);
            ws.Week__c = 'Week ' + w;
            ws.Month__c = monthName;
            ws.Year__c = yearVal;
            ws.Estimated_Hours__c = estimatedHoursByWeek.get(w);
            ws.Billable_Hours__c = billableHoursByWeek.get(w);
            ws.Non_Billable_Hours__c = nonBillableHoursByWeek.get(w);
            ws.Summary__c = 'Summary for ' + ws.Name;
            snapshotsToInsert.add(ws);
        }

        if (!snapshotsToInsert.isEmpty()) {
            insert snapshotsToInsert;
        }
    }

    global void finish(Database.BatchableContext bc) {
        // Optional post-processing or notifications
    }
}

//Scheduling this batch Apex monthly at midnight can be done via: (anonymous window)

String cronExpression = '0 0 0 1 * ?'; // 1st day of every month at midnight
System.schedule('Monthly Weekly Snapshot', cronExpression, new MonthlyWeeklySnapshotScheduler());
===========================================================================================================================================

Question 3:

trigger OpportunityPointsTrigger on Opportunity (after insert, after update, after delete, after undelete) {
    if (Trigger.isAfter) {
        if (Trigger.isInsert || Trigger.isUpdate || Trigger.isUndelete) {
            OpportunityPointsHandler.updateAccountPoints(Trigger.newMap.keySet());
        }
        if (Trigger.isDelete) {
            OpportunityPointsHandler.updateAccountPoints(Trigger.oldMap.keySet());
        }
    }
}

public class OpportunityPointsHandler {
    public static void updateAccountPoints(Set<Id> opportunityAccountIds) {
        if(opportunityAccountIds == null || opportunityAccountIds.isEmpty()) return;

        // Query Opportunities for these accounts
        Map<Id, List<Opportunity>> accountIdToOpps = new Map<Id, List<Opportunity>>();
        for(Opportunity opp : [
            SELECT Id, StageName, AccountId 
            FROM Opportunity 
            WHERE AccountId IN :opportunityAccountIds
        ]) {
            if (!accountIdToOpps.containsKey(opp.AccountId)) {
                accountIdToOpps.put(opp.AccountId, new List<Opportunity>());
            }
            accountIdToOpps.get(opp.AccountId).add(opp);
        }

        List<Account> accountsToUpdate = new List<Account>();

        for (Id accountId : opportunityAccountIds) {
            List<Opportunity> opps = accountIdToOpps.get(accountId);
            Integer totalOppCount = (opps == null) ? 0 : opps.size();
            Integer closedWonCount = 0;

            if (opps != null) {
                for (Opportunity opp : opps) {
                    if (opp.StageName == 'Closed Won') {
                        closedWonCount++;
                    }
                }
            }

            Integer points = 0;
            if (closedWonCount > 5) {
                // Each Closed Won opp counts 2 points
                points = closedWonCount * 2;
                // Non-closed won opps add 1 point each
                points += (totalOppCount - closedWonCount) * 1;
            } else {
                // Each opp counts 1 point except Closed Lost(0)
                for (Opportunity opp : (opps==null ? new List<Opportunity>():opps)){
                    if (opp.StageName != 'Closed Lost') {
                        points +=1;
                    }
                }
            }

            accountsToUpdate.add(new Account(Id=accountId, Points__c=points));
        }

        if (!accountsToUpdate.isEmpty()) {
            update accountsToUpdate;
        }
    }
}

============================================================================================================================================

Question 4:

// Queueable Apex class to collect Leads with status 'Working - Contacted'
public class LeadCollectorQueueable implements Queueable {
    public List<Id> leadIds;

    public void execute(QueueableContext context) {
        List<Lead> leads = [SELECT Id, OwnerId FROM Lead WHERE Status = 'Working - Contacted'];
        leadIds = new List<Id>();
        for (Lead l : leads) {
            leadIds.add(l.Id);
        }

        // Enqueue the task creator queueable passing lead Id list
        if (!leadIds.isEmpty()) {
            System.enqueueJob(new TaskCreatorQueueable(leadIds));
        }
    }
}

// Queueable Apex class to create Tasks for Leads collected
public class TaskCreatorQueueable implements Queueable {
    private List<Id> leadIds;

    public TaskCreatorQueueable(List<Id> leadIds) {
        this.leadIds = leadIds;
    }

    public void execute(QueueableContext context) {
        List<Task> tasksToCreate = new List<Task>();

        // Query leads again to get OwnerId for each lead Id
        List<Lead> leads = [SELECT Id, OwnerId FROM Lead WHERE Id IN :leadIds];
        for (Lead l : leads) {
            Task t = new Task();
            t.OwnerId = l.OwnerId;
            t.WhatId = l.Id; // Task related to the Lead
            t.Subject = 'Follow-up on Lead';
            t.Priority = 'Normal';
            t.Status = 'Not Started';
            tasksToCreate.add(t);
        }

        if (!tasksToCreate.isEmpty()) {
            insert tasksToCreate;
        }
    }
}

*/

public class DEMOCLASSTXT {
	@AuraEnabled
	public static void LightningStudio(){
		System.debug('Lightning Studio');
	}
}