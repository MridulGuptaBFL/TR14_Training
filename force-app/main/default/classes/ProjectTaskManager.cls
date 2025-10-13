public class ProjectTaskManager { //question 6

    // Method to create a new Case as a Project Task
    public static void addNewTask(Id projectId, String subject, String status) {
        Case newTask = new Case();
        newTask.Project__c = projectId; 
        newTask.Subject = subject;
        newTask.Status = status; 
        insert newTask;
        updateNumberOfTasksOnProject(projectId);
        System.debug('New Task Created with Id: ' + newTask.Id);
    }
     
    // Method to update the number of Cases for a given Project
    public static void updateNumberOfTasksOnProject(Id projectId) {
        Integer taskCount = [SELECT COUNT() FROM Case WHERE Project__c = :projectId];
        List<Case> projectCases = [SELECT Id, Number_of_Tasks_on_Project__c FROM Case WHERE Project__c = :projectId];
        for (Case c : projectCases) {
            c.Number_of_Tasks_on_Project__c = taskCount;
        }
        if (!projectCases.isEmpty()) {
            update projectCases;
            System.debug('Updated Number_of_Tasks_on_Project__c to: ' + taskCount + ' for Cases: ' + projectCases);
        } else {
            System.debug('No Cases found for Project Id: ' + projectId);
        }
    }
}
//ProjectTaskManager.addNewTask('<ID>', 'Test Subject', 'New');