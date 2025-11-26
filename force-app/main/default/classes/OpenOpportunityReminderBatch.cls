/**
 * @author Mridul Krishna Gupta
 * @email mridul.gupta@theblueflamelabs.com
 * @created date 11-11-2025
 * @desc Batch class to process open opportunities and create reminder tasks for Sales Representatives.
 *       Identifies open opportunities with open tasks/events from the last 5 days and creates 
 *       a single reminder task per opportunity to the opportunity owner. Uses Database.Stateful 
 *       to accumulate tasks across batch chunks and performs DML insert in finish method.
 */

public class OpenOpportunityReminderBatch implements Database.Batchable<SObject>, Database.Stateful {
    
    // Accumulate tasks across execute() calls and insert once in finish()
    private List<Task> tasksToCreate = new List<Task>();
    

    /**
     * @description This method returns a QueryLocator for all open opportunities.
     *              It queries opportunities with IsClosed = false to identify candidates
     *              for reminder task creation.
     * @author Mridul Krishna Gupta
     * @param  bc             :   Database.BatchableContext - context of batch execution
     * @return Database.QueryLocator - query result set of open opportunities with Id and OwnerId
    */
    public Database.QueryLocator start(Database.BatchableContext bc) {
        // Query all open opportunities
        String query = 'SELECT Id, OwnerId FROM Opportunity WHERE IsClosed = false';
        return Database.getQueryLocator(query);
    }
    

    /**
     * @description This method processes a batch of open opportunities and identifies those with
     *              open tasks or events from the last 5 days. For each qualifying opportunity,
     *              it prepares a reminder task (without inserting) to be inserted in finish method.
     *              Prevents duplicate reminders by checking existing open reminder tasks.
     * @author Mridul Krishna Gupta
     * @param  bc             :   Database.BatchableContext - context of batch execution
     * @param  opportunities  :   List<Opportunity> - batch of open opportunities to process
     * @return void
    */
    public void execute(Database.BatchableContext bc, List<Opportunity> opportunities) {
        Set<Id> opportunityIds = new Set<Id>();
        for (Opportunity opp : opportunities) {
            opportunityIds.add(opp.Id);
        }
        
        if (opportunityIds.isEmpty()) {
            return;
        }
        
        // Find opportunities with open tasks/events in last 5 days
        DateTime fiveDaysAgo = System.now().addDays(-5);
        
        List<Task> openTasks = [
            SELECT Id, WhatId 
            FROM Task 
            WHERE WhatId IN :opportunityIds 
            AND IsClosed = false 
            AND CreatedDate >= :fiveDaysAgo
        ];
        
        List<Event> openEvents = [
            SELECT Id, WhatId 
            FROM Event 
            WHERE WhatId IN :opportunityIds 
            AND IsAllDayEvent = false 
            AND (StartDateTime >= :fiveDaysAgo OR EndDateTime >= :fiveDaysAgo)
        ];
        
        // Get opportunities with open tasks/events
        Set<Id> oppIdsWithActivity = new Set<Id>();
        for (Task task : openTasks) {
            if (task.WhatId != null) oppIdsWithActivity.add(task.WhatId);
        }
        for (Event event : openEvents) {
            if (event.WhatId != null) oppIdsWithActivity.add(event.WhatId);
        }
        
        if (oppIdsWithActivity.isEmpty()) {
            return;
        }
        
        // Query opportunities with activity and their owners
        Map<Id, Opportunity> oppMap = new Map<Id, Opportunity>([
            SELECT Id, OwnerId 
            FROM Opportunity 
            WHERE Id IN :oppIdsWithActivity
        ]);
        
        // Check if reminder task already exists for each opportunity
        List<Task> existingReminders = [
            SELECT WhatId 
            FROM Task 
            WHERE WhatId IN :oppIdsWithActivity 
            AND Subject LIKE 'Reminder:%'
            AND IsClosed = false
        ];
        
        Set<Id> oppWithReminders = new Set<Id>();
        for (Task reminder : existingReminders) {
            if (reminder.WhatId != null) oppWithReminders.add(reminder.WhatId);
        }
        
        // Prepare reminder tasks (do not insert here)
        for (Id oppId : oppIdsWithActivity) {
            if (!oppWithReminders.contains(oppId) && oppMap.containsKey(oppId)) {
                Opportunity opp = oppMap.get(oppId);
                Task reminderTask = new Task(
                    Subject = 'Reminder: Follow up on open tasks',
                    WhatId = oppId,
                    OwnerId = opp.OwnerId,
                    ActivityDate = System.today(),
                    Status = 'Open',
                    Priority = 'High',
                    Description = 'Open tasks/events found related to this opportunity from the last 5 days.'
                );
                tasksToCreate.add(reminderTask);
            }
        }
    }
    

    /**
     * @description This method executes after all batches have been processed. It performs
     *              a single DML insert operation to create all accumulated reminder tasks.
     *              Catches and logs any DmlException errors that occur during insertion.
     * @author Mridul Krishna Gupta
     * @param  bc             :   Database.BatchableContext - context of batch execution
     * @return void
    */
    public void finish(Database.BatchableContext bc) {
        if (!tasksToCreate.isEmpty()) {
            try {
                insert tasksToCreate;
            } catch (DmlException e) {
                // Log the error; in production could notify admin
                System.debug('Error inserting reminder tasks: ' + e.getMessage());
            }
        }
        System.debug('OpenOpportunityReminderBatch completed successfully');
    }
}