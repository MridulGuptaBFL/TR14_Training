public with sharing class ScheduleVisitController {
    @AuraEnabled
    public static Id createTask(String propertyId, String contactName, String visitDate, String reason){
        try {
            if (String.isBlank(contactName)) {
                throw new AuraHandledException('Contact name is required.');
            }
            List<Contact> contactList = [SELECT Id, Name FROM Contact WHERE Id = :contactName LIMIT 1];
            if (contactList.isEmpty()) {
                throw new AuraHandledException('Contact not found with the provided name.');
            }

            List<Property__c> propertyList = [SELECT Name FROM Property__c WHERE Id = :propertyId LIMIT 1];
            if (propertyList.isEmpty()) {
                 throw new AuraHandledException('Property not found with the provided Id.' + propertyId);
             }

            Date parsedDate;
            try {
                parsedDate = Date.valueOf(visitDate);
            } catch (Exception e) {
                throw new AuraHandledException('Invalid visit date format.');
            }
            Task t = new Task();
            t.Subject = contactList[0].Name + ' Visits - ' + propertyList[0].Name;
            t.Description = reason;
            t.ActivityDate = parsedDate;
            t.WhoId = contactList[0].Id;
            insert t;
            return t.Id;
        } catch (AuraHandledException e) {
            throw e;
        } catch (Exception e) {
            throw new AuraHandledException('An unexpected error occurred while scheduling the visit: ' + e.getMessage());
        }
    }
}