/**
* @File Name : TaskWebService.cls
* @Description :
* @Author :
* @Last Modified By :
* @Last Modified On : October 31, 2025
* @Modification Log :
*==============================================================================
* Ver | Date | Author | Modification
*==============================================================================
* 1.0 | October 31, 2025 |   | Initial Version
**/

@RestResource(urlMapping='/taskservice') 
global class TaskWebService { 
@HttpPost 
    global static Id createTask(string status, string priority, string subject){ 
        Task newTask= new Task(); 
        newTask.Status=status; 
        newTask.Priority=priority; 
        newTask.Subject=subject; 
        newTask.OwnerId='005gL000005R7sAQAS'; 
        insert newTask; 
        return newTask.Id; 
    } 
}