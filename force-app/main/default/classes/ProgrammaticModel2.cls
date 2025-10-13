public with sharing class ProgrammaticModel2 {
    
    public static List<Account> findAccountsByPrefix(String searchString) { //question 1
        String searchPattern = searchString + '*'; // Wildcard for prefix matching
        List<List<SObject>> searchResults = [FIND :searchPattern IN ALL FIELDS RETURNING Account(Id, Name)];
        System.debug(searchResults[0]);
        return (List<Account>)searchResults[0];
    }

    public static void updateRecordsStartingWithTest(){ //question 2
        String searchPattern = 'test*';
        
        List<List<SObject>> results = 
            [FIND :searchPattern IN ALL FIELDS RETURNING Account(Id, Name, Active__c), 
            Case(Id, Status), Opportunity(Id, StageName)];
        
        List<Account> accounts = (List<Account>)results[0];
        List<Case> cases = (List<Case>)results[1];
        List<Opportunity> opportunities = (List<Opportunity>)results[2];
        for(Account acc : accounts){
            acc.Active__c = false;
        }
        for(Case c : cases){
            c.Status = 'Closed';    
        }
        for(Opportunity o : opportunities){
            o.StageName = 'Closed Won';
        }
        update accounts;
        update cases;   
        update opportunities;
        System.debug(accounts);
        System.debug(cases);
        System.debug(opportunities);
    }

    //question 3
    public static void closedWonOpportunitiesInLastThirtyDays(){
    //query:
    List<Opportunity> opps = [
        SELECT Id, Name, CloseDate, Amount,
            (SELECT Id, QuoteNumber, AccountId FROM Quotes) 
        FROM Opportunity 
        WHERE StageName = 'Closed Won' 
         AND CloseDate = NEXT_N_DAYS:30 
        ORDER BY CloseDate ASC 
    ];
    //updation: cannot do as the quotes' AccountId is read-only
    // so commenting out the update logic
    // List<Quote> quotesToUpdate = new List<Quote>();
    // for (Opportunity opp : opps) {
    //     for (Quote q : opp.Quotes) {
    //         q.AccountId = opp.AccountId;
    //         quotesToUpdate.add(q);
    //     }
    // }
    // if(!quotesToUpdate.isEmpty())
    //     update quotesToUpdate;
    // System.debug(quotesToUpdate);
    // }
    System.debug(opps);
    }

    //question 4
    public static void projectsHavingACase(){
        List<Project__c> projectsWithTasks = [
            SELECT Id, Name
            FROM Project__c 
            WHERE Id IN (SELECT Project__c FROM Case WHERE Project__c != null)
        ];
        System.debug(projectsWithTasks);
    }

    //question 5
    public static void contactsCountWithDuplicateLastName(){
        List<AggregateResult> duplicateContacts = [ //Error: Illegal assignment from List<AggregateResult> to List<Contact> (76:23)
            SELECT LastName, COUNT(Id) cnt
            FROM Contact 
            GROUP BY LastName
            HAVING COUNT(Id) > 1
        ];
        System.debug(duplicateContacts);
    }
}