/**
 * @author Mridul Krishna Gupta
 * @email mridul.gupta@theblueflamelabs.com
 * @created date 14-11-2025
 * @desc Test class for OpportunityTriggerHandler.
 *       Verifies lead conversion, account/contact auto-creation, and bulk operations.
 */
@IsTest
private class OpportunityTriggerHandlerTest {
 
    /**
     * @description Creates a test user with Sales Team profile.
     * @author Mridul Krishna Gupta
     * @return User The created test user
     */
    private static User createTestUser() {
        Profile standardProfile = [SELECT Id FROM Profile WHERE Name = 'Sales Team' LIMIT 1];
        User testUser = new User(
            Alias              = 'tusr' + Math.abs(Crypto.getRandomInteger()),
            Email              = 'testuser' + Datetime.now().getTime() + '@example.com',
            EmailEncodingKey   = 'UTF-8',
            LastName           = 'Tester',
            LanguageLocaleKey  = 'en_US',
            LocaleSidKey       = 'en_US',
            TimeZoneSidKey     = 'Asia/Kolkata',
            ProfileId          = standardProfile.Id,
            Username           = 'testuser' + Datetime.now().getTime() + '@example.com'
        );
        insert testUser;
        return testUser;
    }

    /**
     * @description Retrieves an Opportunity RecordType ID for test data setup.
     * @author Mridul Krishna Gupta
     * @return Id RecordType Id or null if not found
     */
    private static Id getOpportunityRecordTypeId() {
        List<RecordType> rts = [SELECT Id FROM RecordType WHERE SObjectType = 'Opportunity' LIMIT 1];
        return rts.isEmpty() ? null : rts[0].Id;
    }
 
    /**
     * @description Tests Lead conversion triggered by matching customer email.
     * @author Mridul Krishna Gupta
     * @return void
     */
    @IsTest
    static void testLeadConversionByCustomerEmail() {
        Id oppRTId = getOpportunityRecordTypeId();
 
        Lead customerLead = new Lead(
            FirstName = 'Email',
            LastName  = 'Match',
            Company   = 'EmailCo',
            Email     = 'customeremail@example.com',
            Phone     = '9991112222'
        );
        insert customerLead;
 
        Opportunity opportunityByEmail = new Opportunity(
            Name              = 'Opportunity - Email Match',
            StageName         = 'Prospecting',
            CloseDate         = Date.today().addDays(30),
            CustomerEmail__c = 'customeremail@example.com',
            RecordTypeId = oppRTId
        );
 
        Test.startTest();
        insert opportunityByEmail;
        Test.stopTest();
 
        Lead convertedLead = [SELECT Id, IsConverted, ConvertedAccountId FROM Lead WHERE Id = :customerLead.Id];
        System.assertEquals(true, convertedLead.IsConverted, 'Lead should be converted by email match.');
 
        Opportunity updatedOpp = [SELECT AccountId FROM Opportunity WHERE Id = :opportunityByEmail.Id];
        System.assertNotEquals(null, updatedOpp.AccountId, 'Opportunity should link to converted account.');
    }
 
    /**
     * @description Tests Lead conversion triggered by matching customer phone.
     * @author Mridul Krishna Gupta
     * @return void
     */
    @IsTest
    static void testLeadConversionByCustomerPhone() {
        Id oppRTId = getOpportunityRecordTypeId();
 
        Lead customerLead = new Lead(
            FirstName = 'Phone',
            LastName  = 'Match',
            Company   = 'PhoneCo',
            Email     = 'phonelead@example.com',
            Phone     = '8885554444'
        );
        insert customerLead;
 
        Opportunity opportunityByPhone = new Opportunity(
            Name               = 'Opportunity - Phone Match',
            StageName          = 'Prospecting',
            CloseDate          = Date.today().addDays(20),
            CustomerPhone__c  = '8885554444',
            RecordTypeId = oppRTId
        );
 
        Test.startTest();
        insert opportunityByPhone;
        Test.stopTest();
 
        Lead convertedLead = [SELECT Id, IsConverted FROM Lead WHERE Id = :customerLead.Id];
        System.assertEquals(true, convertedLead.IsConverted, 'Lead should be converted by phone match.');
 
        Opportunity updatedOpp = [SELECT AccountId FROM Opportunity WHERE Id = :opportunityByPhone.Id];
        System.assertNotEquals(null, updatedOpp.AccountId, 'Opportunity should link to converted account.');
    }
 
    /**
     * @description Tests auto-creation of Account and Contact when no matching Lead exists.
     * @author Mridul Krishna Gupta
     * @return void
     */
    @IsTest
    static void testAutoAccountContactCreation() {
        Id oppRTId = getOpportunityRecordTypeId();
 
        Opportunity opportunityWithoutLead = new Opportunity(
            Name               = 'Opportunity - No Lead',
            StageName          = 'Prospecting',
            CloseDate          = Date.today().addDays(15),
            CustomerName__c   = 'Acme Industries',
            CustomerEmail__c  = 'nolead@example.com',
            CustomerPhone__c  = '1234567890',
            RecordTypeId = oppRTId
        );
 
        Test.startTest();
        insert opportunityWithoutLead;
        Test.stopTest();
 
        Opportunity updatedOpp = [SELECT AccountId FROM Opportunity WHERE Id = :opportunityWithoutLead.Id];
        System.assertNotEquals(null, updatedOpp.AccountId, 'Account should be auto-created.');
 
        List<Contact> relatedContacts = [
            SELECT Id, Email FROM Contact WHERE AccountId = :updatedOpp.AccountId
        ];
        System.assert(relatedContacts.size() > 0, 'A Contact should be created for the Account.');
        System.assertEquals('nolead@example.com', relatedContacts[0].Email, 'Email must match.');
    }
 
    /**
     * @description Tests bulk insert of 10 Opportunities with mixed lead matching and auto-creation scenarios.
     * @author Mridul Krishna Gupta
     * @return void
     */
    @IsTest
    static void testBulkOpportunityInsert() {
        Id oppRTId = getOpportunityRecordTypeId();
        Integer totalRecords = 10;
        List<Lead> bulkLeads = new List<Lead>();
        List<Opportunity> bulkOpportunities = new List<Opportunity>();
 
        // Create 10 Leads
        for (Integer i = 0; i < totalRecords; i++) {
            bulkLeads.add(new Lead(
                FirstName = 'Bulk',
                LastName  = 'Lead' + i,
                Company   = 'BulkCo',
                Email     = 'bulk' + i + '@example.com',
                Phone     = '999000' + i
            ));
        }
        insert bulkLeads;
 
        // Create Opportunities (half match existing leads by Customer_Email__c)
        for (Integer i = 0; i < totalRecords; i++) {
            Opportunity newOpportunity = new Opportunity(
                Name      = 'Bulk Opportunity ' + i,
                StageName = 'Prospecting',
                CloseDate = Date.today().addDays(30),
                RecordTypeId = oppRTId
            );
 
            // Even index → matches existing lead
            if (Math.mod(i, 2) == 0) {
                newOpportunity.CustomerEmail__c = 'bulk' + i + '@example.com';
            }
            // Odd index → no lead, triggers Account/Contact creation
            else {
                newOpportunity.CustomerName__c  = 'Bulk Customer ' + i;
                newOpportunity.CustomerEmail__c = 'noLead' + i + '@example.com';
                newOpportunity.CustomerPhone__c = '11122233' + i;
            }
 
            bulkOpportunities.add(newOpportunity);
        }
 
        Test.startTest();
        insert bulkOpportunities;
        Test.stopTest();
 
        // Assert: All Opportunities must have an Account linked (either from Lead conversion or new Account)
        Integer linkedOppCount = [
            SELECT COUNT() FROM Opportunity WHERE Id IN :bulkOpportunities AND AccountId != NULL
        ];
        System.assertEquals(totalRecords, linkedOppCount, 'All Opportunities should link to an Account.');
    }
}