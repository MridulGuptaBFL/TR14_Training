public class ProjectTaskHelper { //Question part [A] Programmatic Model 1

    // Q1: Fetch all Project Task records and form set of Project Ids
    public static Set<Id> getAllProjectTaskProjectIds() {
        List<Case> projectTasks = [
            SELECT Id, Project__c
            FROM Case
            WHERE Project__c != null
        ];
        Set<Id> projectIds = new Set<Id>();
        for (Case pt : projectTasks) {
            if (pt.Project__c != null) {
                projectIds.add(pt.Project__c);
            }
        }
        return projectIds;
    }

    // Q2: Fetch any 5 details of Project by Project Task Id
    public static Project__c getProjectDetailsByTaskId(Id projectTaskId) {
        Case t = [SELECT Project__c FROM Case WHERE Id = :projectTaskId LIMIT 1];
        if (t.Project__c == null) return null;
        return [
            SELECT Name, Project_Description__c, Project_Status__c, Project_start_date__c, Billing_Per_Hour__c
            FROM Project__c
            WHERE Id = :t.Project__c
            LIMIT 1
        ];
    }

    // Q3: Save Project Task with exception handling and friendlier error message
    public static String saveProjectTaskWithError(Case projectTask) {
        try {
            insert projectTask;
            return 'Record saved successfully';
        } catch (Exception ex) {
            return 'Error While saving record to database: ' + ex.getMessage();
        }
    }

    // Q4: List of unique and duplicate characters (optimized)
    public static Map<String, List<String>> getUniquesAndDuplicates(List<String> chars) {
        Set<String> uniques = new Set<String>();
        Set<String> duplicates = new Set<String>();
        for (String c : chars) {
            if (!uniques.add(c)) {
                duplicates.add(c);
            }
        }
        return new Map<String, List<String>>{
            'uniques' => new List<String>(uniques),
            'duplicates' => new List<String>(duplicates)
        };
    }
}


/*
 * // Q1 usage
Set<Id> projectIds = ProjectTaskHelper.getAllProjectTaskProjectIds();



// Q2 usage for a given Case Id
Project__c projectRecord = ProjectTaskHelper.getProjectDetailsByTaskId('500XXXXXXXXXXXX');



// Q3 usage (create a Case record with at least three custom fields set)
Case newTask = new Case(
    Subject = 'Example Task',
    Project__c = 'a01XXXXXXXXXXXX',
    Assignment_Status__c = 'Assigned',
    Billable_Hours__c = 8
);
String result = ProjectTaskHelper.saveProjectTaskWithError(newTask);



// Q4 usage
List<String> charList = new List<String>{'a','b','c','d','e','f','a','b','t','w','e','z'};
Map<String, List<String>> res = ProjectTaskHelper.getUniquesAndDuplicates(charList);
List<String> uniqueChars = res.get('uniques');
List<String> duplicateChars = res.get('duplicates');

*/