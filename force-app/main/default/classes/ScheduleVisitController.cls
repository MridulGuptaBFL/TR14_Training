/**
* @File Name : ScheduleVisitController.cls
* @Description :
* @Author :
* @Last Modified By :
* @Last Modified On : October 12, 2025
* @Modification Log :
*==============================================================================
* Ver | Date | Author | Modification
*==============================================================================
* 1.0 | October 12, 2025 |   | Initial Version
**/

public with sharing class ScheduleVisitController { 

    @AuraEnabled 
    public static void createTask(Id propertyId, String contactName, Date visitDate, String reason) { 
        Contact con = [SELECT Id FROM Contact WHERE Name = :contactName LIMIT 1]; 
        Task t = new Task(); 
        t.Subject = 'Site Visit for Property'; 
        t.WhatId = propertyId; 
        t.WhoId = con.Id; 
        t.ActivityDate = visitDate; 
        t.Description = reason; 
        insert t; 
    } 
}