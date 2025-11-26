public class AccountContactManager { //question 7
 
    // Method to create required Account and Contact records
    public static void createRecords() {
        // Create Blueflame Labs Account
        Account acc1 = new Account(
            Name = 'Blueflame Labs',
            AccountNumber = 'BFL0001',
            Phone = '987654321',
            NumberOfEmployees = 200
        );
        
        // Create BFL Account
        Account acc2 = new Account(
            Name = 'BFL',
            AccountNumber = 'BFL0002',
            Phone = '987654321',
            Industry = 'Technology',
            BillingCountry = 'India',
            BillingCity = 'Pune',
            BillingState = 'Maharashtra'
        );
        
        insert new List<Account>{acc1, acc2};
        System.debug('Inserted Accounts: ' + acc1.Id + ', ' + acc2.Id);
 
        // Create Contact for BFL account
        Contact con = new Contact(
            AccountId = acc2.Id,
            FirstName = 'Andrue',
            LastName = 'Grey'
        );
        insert con;
        System.debug('Inserted Contact Id: ' + con.Id);
    }
 
    // // Method to retrieve accounts using SOQL ~self test
    // public static void getAccounts() {
    //     List<Account> accList = [SELECT Id, Name, AccountNumber, Phone, Industry, BillingCity, BillingState FROM Account WHERE Name IN ('Blueflame Labs', 'BFL')];
    //     for (Account acc : accList) {
    //         System.debug('Account Result: ' + acc);
    //     }
    // }
    
    // // Method to search for records using SOSL ~self test
    // public static void searchRecords() {
    //     List<List<SObject>> searchResults = [FIND 'Blueflame*' IN ALL FIELDS RETURNING Account(Id, Name, AccountNumber), Contact(Id, FirstName, LastName)];
    //     System.debug('SOSL Search Results: ' + searchResults);
    // }
    
    // Method to merge BFL into Blueflame Labs using Database class
    public static void mergeAccounts() {
        Account master = [SELECT Id FROM Account WHERE Name = 'Blueflame Labs' LIMIT 1];
        Account duplicate = [SELECT Id FROM Account WHERE Name = 'BFL' LIMIT 1];
        Database.MergeResult result = Database.merge(master, duplicate, false);
        if (result.isSuccess()) {
            System.debug('Accounts merged. Master Id: ' + master.Id);
        } else {
            System.debug('Merge failed: ' + result.getErrors());
        }
    }
}
 
/*
---- Test: ----
AccountContactManager.createRecords();
AccountContactManager.getAccounts();
AccountContactManager.searchRecords();
AccountContactManager.mergeAccounts();
-----------------------------------------------------
*/