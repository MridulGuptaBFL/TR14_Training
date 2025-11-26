/**
 * @author Your name
 * @email your email
 *  @created date 10-10-2022
 * @desc Class description
 */
 
//Method Level Comment
 
/**
     * @description This method is used to perform callout
     * @author Your Name
     * @param  recordId             :   lens configurator Id 
     * @param  applicableBrand      :   brand
     * @return Return Value
*/
@isTest  
public class MonthlyWeeklySnapshotBatchTest {  

@testSetup  
static void setupTestData() {  
    // Determine current month  
    Date today = Date.today();  
    Integer currentMonth = today.month();  
    Integer currentYear = today.year();  
    Date firstDay = Date.newInstance(currentYear, currentMonth, 1);  
    List<Task> tasks = new List<Task>();  
 
 
    // Create tasks for multiple days so multiple weeks exist  
    tasks.add(new Task(Subject='Task 1', ActivityDate=firstDay));           // Day 1  
    tasks.add(new Task(Subject='Task 2', ActivityDate=firstDay.addDays(2))); // Day 3  
    tasks.add(new Task(Subject='Task 3', ActivityDate=firstDay.addDays(5))); // Day 6  
    tasks.add(new Task(Subject='Task 4', ActivityDate=firstDay.addDays(10))); // Day 11  
    insert tasks;  
}  
 
@isTest  
static void testBatchExecution() {  
 
    Test.startTest();  
    // Execute batch  
    MonthlyWeeklySnapshotBatch batch = new MonthlyWeeklySnapshotBatch();  
    Database.executeBatch(batch, 50);  
    Test.stopTest();  
 
    // Verify Weekly Snapshot records created  
    List<Weekly_Snapshot__c> snapshots = [SELECT Id, Name, Week_Start_Date__c, Week_End_Date__c FROM Weekly_Snapshot__c];  
 
    System.assert(!snapshots.isEmpty(), 'Weekly Snapshot records should have been created');  
    System.assert(snapshots.size() > 0, 'There should be at least 1 snapshot');  
}  
}