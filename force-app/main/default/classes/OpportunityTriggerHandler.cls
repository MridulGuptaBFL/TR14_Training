/**
 * @author Mridul Krishna Gupta
 * @email mridul.gupta@theblueflamelabs.com
 * @created date 14-11-2025
 * @desc Handles after insert trigger logic for Opportunity records.
 *       Converts matching Leads to Accounts, creates new Accounts/Contacts
 *       for Opportunities without Lead matches, and manages Record Type mappings.
 */
public class OpportunityTriggerHandler {
    
    /**
     * @description Main handler method for after insert trigger on Opportunity.
     *              Processes lead conversion, account creation, and contact management.
     * @author Mridul Krishna Gupta
     * @param oppList List of newly inserted Opportunity records
     * @return void
     */
    public static void afterInsert(List<Opportunity> oppList) {
        // -----------------------------
        // 1. OPP RT FETCH (Retail/Wholesale)
        // -----------------------------
        Set<Id> oppRTIds = new Set<Id>();
        for (Opportunity o : oppList) {
            if (o.RecordTypeId != null) oppRTIds.add(o.RecordTypeId);
        }
        Map<Id, RecordType> oppRTMap = new Map<Id, RecordType>();
        if (!oppRTIds.isEmpty()) {
            oppRTMap = new Map<Id, RecordType>(
                [SELECT Id, DeveloperName FROM RecordType WHERE Id IN :oppRTIds]
            );
        }
        
        // -----------------------------
        // 2. ACCOUNT RT FETCH
        // -----------------------------
        Map<String, RecordType> accRTMap = new Map<String, RecordType>();
        List<RecordType> accRts = [SELECT Id, DeveloperName FROM RecordType WHERE SObjectType='Account'];
        for (RecordType rt : accRts) {
            accRTMap.put(rt.DeveloperName.toLowerCase(), rt);
        }
        
        Map<Id, Id> oppToAccRT = new Map<Id, Id>();
        for (Opportunity opp : oppList) {
            if (opp.RecordTypeId == null) continue;
            
            RecordType oppRT = oppRTMap.get(opp.RecordTypeId);
            if (oppRT == null) continue;
            
            String oppDev = oppRT.DeveloperName.toLowerCase();
            for (String accDevKey : accRTMap.keySet()) {
                if ((oppDev.contains('retail') && accDevKey.contains('retail')) ||
                    (oppDev.contains('wholesale') && accDevKey.contains('wholesale'))) {
                    oppToAccRT.put(opp.Id, accRTMap.get(accDevKey).Id);
                    break;
                }
            }
            // Fallback: if no matching RT found, don't set one
            if (!oppToAccRT.containsKey(opp.Id)) {
                oppToAccRT.put(opp.Id, null);
            }
        }
        
        // -----------------------------
        // 3. MATCH LEAD BY EMAIL/PHONE
        // -----------------------------
        Set<String> emails = new Set<String>();
        Set<String> phones = new Set<String>();
        for (Opportunity opp : oppList) {
            if (opp.CustomerEmail__c != null) emails.add(opp.CustomerEmail__c.toLowerCase().trim());
            if (opp.CustomerPhone__c != null) phones.add(opp.CustomerPhone__c.trim());
        }
        Map<String, Lead> emailLeadMap = new Map<String, Lead>();
        Map<String, Lead> phoneLeadMap = new Map<String, Lead>();
        if (!emails.isEmpty() || !phones.isEmpty()) {
            for (Lead l : [
                SELECT Id, Email, Phone 
                FROM Lead
                WHERE IsConverted = FALSE
                AND (Email IN :emails OR Phone IN :phones)
            ]) {
                if (l.Email != null) emailLeadMap.put(l.Email.toLowerCase(), l);
                if (l.Phone != null) phoneLeadMap.put(l.Phone, l);
            }
        }
        
        // -----------------------------
        // 4. LEAD CONVERSION
        // -----------------------------
        String convertedStatus = 'Closed - Converted';
        try {
            convertedStatus = [
                SELECT MasterLabel 
                FROM LeadStatus 
                WHERE IsConverted = TRUE 
                LIMIT 1
            ].MasterLabel;
        } catch (Exception e) {
            System.debug('Could not fetch converted status: ' + e.getMessage());
        }
        
        List<Database.LeadConvert> lcList = new List<Database.LeadConvert>();
        Map<Id, Id> leadToOpp = new Map<Id, Id>();
        for (Opportunity opp : oppList) {
            Lead matched = null;
            if (opp.CustomerEmail__c != null &&
                emailLeadMap.containsKey(opp.CustomerEmail__c.toLowerCase().trim())) {
                matched = emailLeadMap.get(opp.CustomerEmail__c.toLowerCase().trim());
            }
            else if (opp.CustomerPhone__c != null &&
                     phoneLeadMap.containsKey(opp.CustomerPhone__c.trim())) {
                matched = phoneLeadMap.get(opp.CustomerPhone__c.trim());
            }
            if (matched != null) {
                Database.LeadConvert lc = new Database.LeadConvert();
                lc.setLeadId(matched.Id);
                lc.setConvertedStatus(convertedStatus);
                lc.setDoNotCreateOpportunity(true);
                lcList.add(lc);
                leadToOpp.put(matched.Id, opp.Id);
            }
        }
        
        List<Account> convertedAccUpdates = new List<Account>();
        List<Opportunity> convertedOppUpdates = new List<Opportunity>();
        if (!lcList.isEmpty()) {
            List<Database.LeadConvertResult> results =
                Database.convertLead(lcList, false);
            for (Database.LeadConvertResult res : results) {
                if (res.isSuccess()) {
                    Id accId = res.getAccountId();
                    Id oppId = leadToOpp.get(res.getLeadId());
                    
                    // 1) Update ACCOUNT RT FIRST
                    if (oppToAccRT.get(oppId) != null) {
                        convertedAccUpdates.add(new Account(
                            Id = accId,
                            RecordTypeId = oppToAccRT.get(oppId)
                        ));
                    }

                    // 2) THEN update Opportunity.AccountId
                    convertedOppUpdates.add(new Opportunity(
                        Id = oppId,
                        AccountId = accId
                    ));
                }
            }
        }
        if (!convertedAccUpdates.isEmpty()) update convertedAccUpdates;
        if (!convertedOppUpdates.isEmpty()) update convertedOppUpdates; 

        // -----------------------------
        // 5. CREATE ACCOUNT (NO LEAD & NO SELECTED ACCOUNT)
        // -----------------------------
        List<Account> newAccList = new List<Account>();
        Map<Integer, Id> newAccIndexToOppId = new Map<Integer, Id>();
        
        for (Opportunity opp : oppList) {
            // Skip lead converted Opps
            Boolean leadConverted = false;
            for (Opportunity o : convertedOppUpdates) {
                if (o.Id == opp.Id) {
                    leadConverted = true;
                    break;
                }
            }
            if (leadConverted) continue;
            
            // If user selected Account and it exists → skip
            if (opp.AccountId != null && accountExists(opp.AccountId)) continue;
            
            // Create NEW Account with failsafe for Name
            Account acc = new Account();
            acc.Name = String.isNotBlank(opp.CustomerName__c) 
                ? opp.CustomerName__c 
                : (String.isNotBlank(opp.Name) ? opp.Name : 'Account-' + Datetime.now().getTime());
            if (oppToAccRT.get(opp.Id) != null) {
                acc.RecordTypeId = oppToAccRT.get(opp.Id);
            }
            newAccIndexToOppId.put(newAccList.size(), opp.Id);
            newAccList.add(acc);
        }
        
        if (!newAccList.isEmpty()) insert newAccList;
        
        // Map Opportunity IDs to newly created Account IDs
        Map<Id, Id> oppToNewAcc = new Map<Id, Id>();
        Integer idx = 0;
        for (Integer i : newAccIndexToOppId.keySet()) {
            oppToNewAcc.put(newAccIndexToOppId.get(i), newAccList[i].Id);
            idx++;
        }
        
        // -----------------------------
        // 6. UPDATE OPP WITH NEW ACCOUNT (NO LEAD CASE)
        // -----------------------------
        List<Opportunity> oppAccountUpdateList = new List<Opportunity>();
        for (Opportunity opp : oppList) {
            Boolean isLeadConverted = false;
            for (Opportunity o : convertedOppUpdates) {
                if (o.Id == opp.Id) {
                    isLeadConverted = true;
                    break;
                }
            }
            if (isLeadConverted) continue;
            
            // If user selected account and it exists → skip updating
            if (opp.AccountId != null && accountExists(opp.AccountId)) continue;
            
            // If we created a new Account → assign it to Opp
            if (oppToNewAcc.containsKey(opp.Id)) {
                oppAccountUpdateList.add(new Opportunity(
                    Id = opp.Id,
                    AccountId = oppToNewAcc.get(opp.Id)
                ));
            }
        }
        if (!oppAccountUpdateList.isEmpty()) update oppAccountUpdateList;
 
        // -----------------------------
        // 7. CREATE CONTACTS
        // -----------------------------
        List<Contact> conList = new List<Contact>();
        for (Opportunity opp : oppList) {
            Boolean isLeadConverted = false;
            for (Opportunity o : convertedOppUpdates) {
                if (o.Id == opp.Id) {
                    isLeadConverted = true;
                    break;
                }
            }
            if (isLeadConverted) continue; // Lead already created Contact
            
            Contact con = new Contact();
            con.FirstName = 'Auto';
            con.LastName = String.isNotBlank(opp.CustomerName__c) 
                ? opp.CustomerName__c 
                : 'Contact';
            con.Email = opp.CustomerEmail__c;
            con.Phone = opp.CustomerPhone__c;
            
            if (opp.AccountId != null && accountExists(opp.AccountId)) {
                con.AccountId = opp.AccountId; // user selected account
            } 
            else if (oppToNewAcc.containsKey(opp.Id)) {
                con.AccountId = oppToNewAcc.get(opp.Id); // newly created
            }
            
            if (con.AccountId != null) {
                conList.add(con);
            }
        }
        if (!conList.isEmpty()) insert conList;
    } 

    /**
     * @description Checks if an Account record exists in the database.
     * @author Mridul Krishna Gupta
     * @param accId Account Id to verify
     * @return Boolean True if Account exists, false otherwise
     */
    private static Boolean accountExists(Id accId) {
        try {
            Account a = [
                SELECT Id FROM Account 
                WHERE Id = :accId 
                LIMIT 1
            ];
            return a != null;
        } catch (Exception e) {
            return false;
        }
    }
}