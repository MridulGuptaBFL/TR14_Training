/**
* @File Name : TaskRestService.cls
* @Description :
* @Author :
* @Last Modified By :
* @Last Modified On : November 2, 2025
* @Modification Log :
*==============================================================================
* Ver | Date | Author | Modification
*==============================================================================
* 1.0 | November 2, 2025 |   | Initial Version
**/

@RestResource(urlMapping='/createTask/')
global with sharing class TaskRestService {

    //  POST method to create a new Task record
    @HttpPost
    global static String createTask() {
        RestRequest req = RestContext.request;
        RestResponse res = RestContext.response;

        try {
            // Step 1: Parse the JSON request body
            String requestBody = req.requestBody.toString();
            TaskWrapper taskData = (TaskWrapper) JSON.deserialize(requestBody, TaskWrapper.class);

            // Step 2: Create a new Task record
            Task newTask = new Task();
            newTask.Subject = taskData.Subject;
            newTask.Status = taskData.Status;
            newTask.Priority = taskData.Priority;
            //newTask.OwnerId='005gL000005R7sAQAS'; 
            newTask.Description = taskData.Description;
            newTask.WhatId = taskData.WhatId;  // Related record (e.g., Account/Opportunity)
            newTask.WhoId = taskData.WhoId;    // Related Contact/Lead (optional)

            insert newTask;

            // Step 3: Return success response
            res.statusCode = 201;
            return JSON.serialize(new ResponseWrapper('Task created successfully', newTask.Id));

        } catch (DmlException dmlEx) {
            res.statusCode = 400;
            return JSON.serialize(new ResponseWrapper('DML Error: ' + dmlEx.getMessage(), null));
        } catch (Exception ex) {
            res.statusCode = 500;
            return JSON.serialize(new ResponseWrapper('Unexpected Error: ' + ex.getMessage(), null));
        }
    }

    // Wrapper class for incoming JSON data
    global class TaskWrapper {
        public String Subject;
        public String Status;
        public String Priority;
        public String Description;
        public Id WhatId;
        public Id WhoId;
    }

    // Wrapper class for response message
    global class ResponseWrapper {
        public String message;
        public Id taskId;

        public ResponseWrapper(String msg, Id tId) {
            this.message = msg;
            this.taskId = tId;
        }
    }
}