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

public class MonthlyWeeklySnapshotScheduler implements Schedulable {
	public void execute(SchedulableContext sc) {  
        // Call your batch class  
        Database.executeBatch(new MonthlyWeeklySnapshotBatch(), 200);
    }
}