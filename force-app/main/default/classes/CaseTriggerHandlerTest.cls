@isTest
private class CaseTriggerHandlerTest {

    @testSetup
    static void setupTestData() {
        Project__c project = new Project__c(Name = 'Alpha Project');
        insert project;
    
        // Two cases: 1 billable (5), 1 billable (3) and non-billable values
        Case newCaseRecord1 = new Case(
            Project__c = project.Id,
            Billable_Hours__c = 5,
            Status = 'New',
            Origin = 'Phone',
            Non_Billable_Hours__c = 2
        );
        Case newCaseRecord2 = new Case(
            Project__c = project.Id,
            Billable_Hours__c = 3,
            Status = 'New',
            Origin = 'Phone',
            Non_Billable_Hours__c = 1
        );
        insert new List<Case>{ newCaseRecord1, newCaseRecord2 };
    }
    
    @isTest
    static void testInsertAndUpdate() {
        // Verify totals after insert (insert happened in @testSetup and triggered handler)
        Project__c projectRecord = [SELECT Id, Billable_Hours__c, Non_Billable_Hours__c FROM Project__c LIMIT 1];
        System.assertEquals(8, projectRecord.Billable_Hours__c);
        System.assertEquals(3, projectRecord.Non_Billable_Hours__c);
    
        // Update the known Case (the one that originally had 5 billable hours)
        Case caseToUpdate = [SELECT Id, Billable_Hours__c FROM Case WHERE Billable_Hours__c = 5 AND Project__c = :projectRecord.Id LIMIT 1];

        Test.startTest();
            caseToUpdate.Billable_Hours__c = 10;  
            update caseToUpdate;
        Test.stopTest();
    
        Project__c projectRecordAfterUpdate = [SELECT Billable_Hours__c, Non_Billable_Hours__c FROM Project__c WHERE Id = :projectRecord.Id];
        // 10 (updated) + 3 (other case) = 13
        System.assertEquals(13, projectRecordAfterUpdate.Billable_Hours__c);
        System.assertEquals(3, projectRecordAfterUpdate.Non_Billable_Hours__c);
    }
    
    @isTest
    static void testDeleteAndUndelete() {
        Project__c projectRecord = [SELECT Id FROM Project__c LIMIT 1];
        List<Case> taskRecords = [SELECT Id FROM Case WHERE Project__c = :projectRecord.Id];
        
        Test.startTest();
            // Delete all cases -> totals should go to zero
            delete taskRecords;
    
        Project__c projectRecordAfterDelete = [SELECT Billable_Hours__c, Non_Billable_Hours__c FROM Project__c WHERE Id = :projectRecord.Id];
        System.assertEquals(0, projectRecordAfterDelete.Billable_Hours__c);
        System.assertEquals(0, projectRecordAfterDelete.Non_Billable_Hours__c);
    
            // Undelete previously deleted cases
            undelete taskRecords;
    
        Project__c projectRecordAfterUndelete = [SELECT Billable_Hours__c, Non_Billable_Hours__c FROM Project__c WHERE Id = :projectRecord.Id];
        System.assertEquals(8, projectRecordAfterUndelete.Billable_Hours__c);
        System.assertEquals(3, projectRecordAfterUndelete.Non_Billable_Hours__c);
        Test.stopTest();

    }
}