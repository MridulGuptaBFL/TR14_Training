/**
 * @author Mridul Krishna Gupta
 * @email mridul.gupta@theblueflamelabs.com
 * @created date 11-11-2025
 * @desc Test class for OpenOpportunityReminderBatch. Validates batch functionality including:
 *       - Creation of reminder tasks for open opportunities with recent activities
 *       - Prevention of duplicate reminders per opportunity
 *       - Exclusion of closed opportunities from processing
 *       - Correct handling of tasks outside the 5-day window
 */
@isTest
private class OpenOpportunityReminderBatchTest {
    
    /**
     * @description Test setup method to initialize common test data used across all test methods.
     *              Creates test account, user (Sales Rep), open opportunity, and open task.
     * @author Mridul Krishna Gupta
     * @return void
    */
    @testSetup
    static void setupTestData() {
        // Create test account
        Account testAccount = new Account(Name = 'Test Account');
        insert testAccount;
        
        // Create test user (Sales Rep)
        User salesRep = new User(
            FirstName = 'John',
            LastName = 'Doe',
            Email = 'john.doe@test.com',
            Username = 'john.doe.test.' + System.currentTimeMillis() + '@example.com',
            ProfileId = [SELECT Id FROM Profile WHERE Name = 'Sales Profile' LIMIT 1].Id,
            Alias = 'jdoe',
            TimeZoneSidKey = 'America/New_York',
            LocaleSidKey = 'en_US',
            EmailEncodingKey = 'UTF-8',
            LanguageLocaleKey = 'en_US'
        );
        insert salesRep;
        
        // Create test opportunity (Owner will be Sales Rep) - use StageName for open status
        Opportunity testOpp = new Opportunity(
            Name = 'Test Opportunity',
            AccountId = testAccount.Id,
            StageName = 'Prospecting',
            CloseDate = System.today().addDays(30),
            OwnerId = salesRep.Id
        );
        insert testOpp;
        
        // Create open task within last 5 days
        Task openTask = new Task(
            Subject = 'Follow up call',
            WhatId = testOpp.Id,
            OwnerId = salesRep.Id,
            ActivityDate = System.today(),
            Status = 'Open',
            Priority = 'High'
        );
        insert openTask;
    }
    
    /**
     * @description Test method to verify that the batch correctly creates a reminder task
     *              for an open opportunity with an open task within the last 5 days.
     *              Validates task count and relationship to opportunity.
     * @author Mridul Krishna Gupta
     * @return void
    */
    @isTest
    static void testBatchCreatesReminderTask() {
        Test.startTest();
        OpenOpportunityReminderBatch batch = new OpenOpportunityReminderBatch();
        Database.executeBatch(batch);
        Test.stopTest();
        
        // Verify reminder task was created
        List<Task> reminderTasks = [
            SELECT Id, Subject, WhatId, OwnerId
            FROM Task 
            WHERE Subject LIKE 'Reminder:%'
        ];
        
        System.assertEquals(1, reminderTasks.size(), 'One reminder task should be created');
        System.assertNotEquals(null, reminderTasks[0].WhatId, 'Reminder task should be related to opportunity');
    }
    
    /**
     * @description Test method to verify that the batch does not create duplicate reminder tasks
     *              when a reminder already exists for the opportunity. Ensures maximum one reminder
     *              task per opportunity constraint is enforced.
     * @author Mridul Krishna Gupta
     * @return void
    */
    @isTest
    static void testBatchDoesNotCreateDuplicateReminders() {
        Opportunity testOpp = [SELECT Id, OwnerId FROM Opportunity LIMIT 1];
        User salesRep = [SELECT Id FROM User WHERE Email = 'john.doe@test.com' LIMIT 1];
        
        // Create existing reminder task
        Task existingReminder = new Task(
            Subject = 'Reminder: Follow up on open tasks',
            WhatId = testOpp.Id,
            OwnerId = salesRep.Id,
            ActivityDate = System.today(),
            Status = 'Open'
        );
        insert existingReminder;
        
        Test.startTest();
        OpenOpportunityReminderBatch batch = new OpenOpportunityReminderBatch();
        Database.executeBatch(batch);
        Test.stopTest();
        
        // Verify no duplicate reminders created
        List<Task> reminderTasks = [
            SELECT Id 
            FROM Task 
            WHERE Subject LIKE 'Reminder:%'
        ];
        
        System.assertEquals(1, reminderTasks.size(), 'Only one reminder task should exist');
    }
    
    /**
     * @description Test method to verify that the batch correctly ignores closed opportunities.
     *              Even if a closed opportunity has open tasks, no reminder task should be created.
     *              Validates that only open opportunities are processed.
     * @author Mridul Krishna Gupta
     * @return void
    */
    @isTest
    static void testBatchIgnoresClosedOpportunities() {
        Account testAccount = [SELECT Id FROM Account LIMIT 1];
        User salesRep = [SELECT Id FROM User WHERE Email = 'john.doe@test.com' LIMIT 1];
        
        // Create closed opportunity
        Opportunity closedOpp = new Opportunity(
            Name = 'Closed Opportunity',
            AccountId = testAccount.Id,
            StageName = 'Closed Won',
            CloseDate = System.today(),
            OwnerId = salesRep.Id
        );
        insert closedOpp;
        
        // Create open task for closed opportunity
        Task taskForClosedOpp = new Task(
            Subject = 'Task on closed opp',
            WhatId = closedOpp.Id,
            OwnerId = salesRep.Id,
            ActivityDate = System.today(),
            Status = 'Open'
        );
        insert taskForClosedOpp;
        
        Test.startTest();
        OpenOpportunityReminderBatch batch = new OpenOpportunityReminderBatch();
        Database.executeBatch(batch);
        Test.stopTest();
        
        // Verify reminder not created for closed opportunity
        List<Task> tasksForClosedOpp = [
            SELECT Id 
            FROM Task 
            WHERE WhatId = :closedOpp.Id 
            AND Subject LIKE 'Reminder:%'
        ];
        
        System.assertEquals(0, tasksForClosedOpp.size(), 'No reminder should be created for closed opportunities');
    }
    
    /**
     * @description Test method to verify that the batch correctly handles tasks outside the 5-day window.
     *              Creates an old task (10 days ago) and verifies that reminder task is still created
     *              based on the recent open task from setupTestData. Validates 5-day lookback logic.
     * @author Mridul Krishna Gupta
     * @return void
    */
    @isTest
    static void testBatchHandlesOldTasks() {
        Opportunity testOpp = [SELECT Id FROM Opportunity LIMIT 1];
        User salesRep = [SELECT Id FROM User WHERE Email = 'john.doe@test.com' LIMIT 1];
        
        // Create old task (older than 5 days)
        Task oldTask = new Task(
            Subject = 'Old task',
            WhatId = testOpp.Id,
            OwnerId = salesRep.Id,
            ActivityDate = System.today().addDays(-10),
            Status = 'Open'
        );
        insert oldTask;
        
        Test.startTest();
        OpenOpportunityReminderBatch batch = new OpenOpportunityReminderBatch();
        Database.executeBatch(batch);
        Test.stopTest();
        
        // Reminder should still be created from the recent open task created in setupTestData
        List<Task> reminderTasks = [
            SELECT Id 
            FROM Task 
            WHERE Subject LIKE 'Reminder:%'
        ];
        
        System.assertEquals(1, reminderTasks.size(), 'Reminder should be created for open opportunities');
    }
}