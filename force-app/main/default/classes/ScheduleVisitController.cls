public with sharing class ScheduleVisitController {
    @AuraEnabled
    public static Id createTask(String propertyId, String contactName, String visitDate, String reason){
        try {
            if (String.isBlank(contactName)) {
                throw new AuraHandledException('Contact name is required.');
            }
            List<Contact> contacts = [SELECT Id FROM Contact WHERE Id = :contactName LIMIT 1];
            if (contacts.isEmpty()) {
                throw new AuraHandledException('Contact not found with the provided name.');
            }
            Date parsedDate;
            try {
                parsedDate = Date.valueOf(visitDate);
            } catch (Exception e) {
                throw new AuraHandledException('Invalid visit date format.');
            }
            Task t = new Task();
            t.Subject = 'Site Visit for ' + propertyId;
            t.Description = reason;
            t.ActivityDate = parsedDate;
            t.WhoId = contacts[0].Id;
            insert t;
            return t.Id;
        } catch (AuraHandledException e) {
            throw e;
        } catch (Exception e) {
            throw new AuraHandledException('An unexpected error occurred while scheduling the visit: ' + e.getMessage());
        }
    }
}