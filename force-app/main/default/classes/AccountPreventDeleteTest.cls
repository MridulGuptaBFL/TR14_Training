@isTest
public class AccountPreventDeleteTest {
    @TestSetup
    static void createTestData() {
        // Account with a Contact
        Account accWithContact = new Account(Name = 'With Contact');
        insert accWithContact;
        Contact con = new Contact(LastName = 'Tester', AccountId = accWithContact.Id);
        insert con;

        // Account without a Contact
        Account accWithoutContact = new Account(Name = 'Without Contact');
        insert accWithoutContact;
    }

    @isTest
    static void cannotDeleteAccountWithContact() {
        Account acc = [SELECT Id FROM Account WHERE Name = 'With Contact' LIMIT 1];
        Test.startTest();
        try {
            delete acc;
            System.assert(false, 'Delete should not be allowed if Contacts exist');
        } catch (DmlException ex) {
            System.assert(ex.getMessage().contains(Label.Account_Error_Apex), 'Custom label error message should appear'+ ex.getMessage());
        }
        Test.stopTest();
    }

    @isTest
    static void canDeleteAccountWithoutContact() {
        Account acc = [SELECT Id FROM Account WHERE Name = 'Without Contact' LIMIT 1];
        Test.startTest();
        delete acc; // Should not throw any error
        Test.stopTest();
        System.assertEquals(0, [SELECT COUNT() FROM Account WHERE Id = :acc.Id], 'Account should have been deleted');
    }
}