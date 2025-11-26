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

public class MonthlyWeeklySnapshotBatch implements Database.Batchable<SObject>, Database.Stateful { 

	public Database.QueryLocator start(Database.BatchableContext bc) { 
		// Query all tasks for the current month 
		Date today = Date.today(); 
		Integer currentMonth = today.month(); 
		Integer currentYear = today.year(); 
	
		Date firstDayOfMonth = Date.newInstance(currentYear, currentMonth, 1); 
		Date lastDayOfMonth = firstDayOfMonth.addMonths(1).addDays(-1); 
	
		return Database.getQueryLocator([ 
			SELECT Id, Subject, ActivityDate 
			FROM Task 
			WHERE ActivityDate >= :firstDayOfMonth AND ActivityDate <= :lastDayOfMonth 
		]); 
	} 
	
	public void execute(Database.BatchableContext bc, List<Task> scope) { 
		// Helper map to group data week-wise 
		Map<String, AggregateData> weeklyMap = new Map<String, AggregateData>(); 
	
		for (Task t : scope) { 
			if (t.ActivityDate == null) continue; 
	
			Date taskDate = t.ActivityDate; 
	
			// Find day of week (1=Monday, 7=Sunday) 
			Integer dow = Integer.valueOf(DateTime.newInstance(taskDate, Time.newInstance(0,0,0,0)).format('u')); 
	
			// Calculate start (Monday) and end (Sunday) of week 
			Integer offsetToMonday = 1 - dow; 
			Date weekStart = taskDate.addDays(offsetToMonday); 
			Date weekEnd = weekStart.addDays(6); 
	
			// Month name and year 
			Integer monthNum = taskDate.month(); 
			Integer yearNum = taskDate.year(); 
			String[] months = new String[]{'January','February','March','April','May','June','July','August','September','October','November','December'}; 
			String monthName = months[monthNum - 1]; 
	
			// Unique key for each week 
			String key = monthName + '-' + yearNum + '-' + weekStart.format(); 
	
			// Initialize if new week entry 
			if (!weeklyMap.containsKey(key)) { 
				weeklyMap.put(key, new AggregateData(weekStart, weekEnd, monthName, yearNum)); 
			} 
	
			AggregateData agg = weeklyMap.get(key); 
	
			// Add your custom logic here to sum up hours 
			// (Right now, just using dummy example values) 
			agg.totalEstimated += 8; 
			agg.totalBillable += 8; 
			agg.totalNonBillable += 2; 
		} 
	
		List<Weekly_Snapshot__c> snapshots = new List<Weekly_Snapshot__c>(); 
	
		Integer weekCount = 1; 
		for (AggregateData data : weeklyMap.values()) { 
			String snapshotName = 'WS-' + data.month + '-W' + weekCount; 
	
			snapshots.add(new Weekly_Snapshot__c( 
				Name = snapshotName, 
				Week_Start_Date__c = data.weekStart, 
				Week_End_Date__c = data.weekEnd, 
				Estimated_Hours__c = data.totalEstimated, 
				Billable_Hours__c = data.totalBillable + 366, // Example as per your requirement 
				Non_Billable_Hours__c = data.totalNonBillable, 
				Month__c = data.month, 
				Year__c = data.year, 
				Week_Unique_Id__c = data.month + '-' + data.year + '-W' + weekCount, 
				Summary__c = 'Summary for week ' + weekCount + ' of ' + data.month + ' ' + data.year 
			)); 
	
			weekCount++; 
		} 
	
		if (!snapshots.isEmpty()) { 
			insert snapshots; 
		} 
	} 
	
	public void finish(Database.BatchableContext bc) { 
		System.debug(' Weekly Snapshot records created successfully.'); 
	} 
 
	// Helper class for aggregation 
	public class AggregateData { 
		public Date weekStart; 
		public Date weekEnd; 
		public String month; 
		public Integer year; 
		public Decimal totalEstimated = 0; 
		public Decimal totalBillable = 0; 
		public Decimal totalNonBillable = 0; 
	
		public AggregateData(Date ws, Date we, String m, Integer y) { 
			weekStart = ws; 
			weekEnd = we; 
			month = m; 
			year = y; 
		} 
	} 
}