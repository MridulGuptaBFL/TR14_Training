public class ProjectTaskDebugHelper { //Question part [B] of Salesforce Programmatic Model 1

    // Q5: Return projectTasks (Case) with matching Due Date
    public static List<Case> getProjectTasksByDueDate(Date inputDate) {
        System.debug('Entering getProjectTasksByDueDate with inputDate: ' + inputDate);
        List<Case> tasks = [SELECT Id, Subject, Project__c, Due_Date__c FROM Case WHERE Due_Date__c = :inputDate];
        System.debug('Found ' + tasks.size() + ' project tasks with Due_Date__c = ' + inputDate);
        return tasks;
    }

    // Q6: Partition cases by creation time window (using created date) into three collections
    public class TaskCollections {
        public List<Case> highPriorityTasks;
        public List<Case> mediumPriorityTasks;
        public List<Case> lowPriorityTasks;
    }

    public static TaskCollections collectTasksByTimeWindows() {
        System.debug('Entering collectTasksByTimeWindows');
        List<Case> allTasks = [SELECT Id, Subject, CreatedDate, Project__c, Due_Date__c FROM Case];

        DateTime nowDt = DateTime.now();
        DateTime last24 = nowDt.addHours(-24);
        DateTime last48 = nowDt.addHours(-48);
        DateTime last96 = nowDt.addHours(-96);

        List<Case> lowPriority = new List<Case>();
        List<Case> mediumPriority = new List<Case>();
        List<Case> highPriority = new List<Case>();

        for (Case t : allTasks) {
            if (t.CreatedDate >= last24 && t.CreatedDate <= nowDt) {
                lowPriority.add(t);
            } else if (t.CreatedDate >= last48 && t.CreatedDate < last24) {
                mediumPriority.add(t);
            } else if (t.CreatedDate >= last96 && t.CreatedDate < last48) {
                highPriority.add(t);
            }
        }

        System.debug('Low priority tasks count (created in last 24 hours): ' + lowPriority.size());
        System.debug('Medium priority tasks count (created between 24 and 48 hours ago): ' + mediumPriority.size());
        System.debug('High priority tasks count (created between 48 and 96 hours ago): ' + highPriority.size());

        TaskCollections output = new TaskCollections();
        output.lowPriorityTasks = lowPriority;
        output.mediumPriorityTasks = mediumPriority;
        output.highPriorityTasks = highPriority;
        return output;
    }
}

/*
 * // Q5: Find all tasks due on today's date
Date today = Date.today();
List<Case> dueTodayTasks = ProjectTaskDebugHelper.getProjectTasksByDueDate(today);



// Q6: Get tasks partitioned by priority time windows
ProjectTaskDebugHelper.TaskCollections taskBuckets = ProjectTaskDebugHelper.collectTasksByTimeWindows();
List<Case> highPriorityTasks = taskBuckets.highPriorityTasks;
List<Case> mediumPriorityTasks = taskBuckets.mediumPriorityTasks;
List<Case> lowPriorityTasks = taskBuckets.lowPriorityTasks;
*/