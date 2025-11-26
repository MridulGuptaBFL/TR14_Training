public with sharing class TaskCalloutService {
 
    public static void createTaskInServerOrg() {
        try {
            HttpRequest req = new HttpRequest();
            req.setEndpoint('callout:Client_SFDC/services/apexrest/createTask/');
            req.setMethod('POST');
            req.setHeader('Content-Type', 'application/json');
 
            // Prepare JSON body
            Map<String, Object> taskData = new Map<String, Object>{
                'Subject' => 'Follow up call from orgfarm-d6d9dc7456',
                'Status' => 'In Progress',
                'Priority' => 'High',
                'Description' => 'Created via REST call from another org'
            };
            req.setBody(JSON.serialize(taskData));
 
            Http http = new Http();
            HTTPResponse res = http.send(req);
 
            System.debug('Status: ' + res.getStatus());
            System.debug('Response: ' + res.getBody());
 
        } catch (Exception ex) {
            System.debug('Callout Error: ' + ex.getMessage());
        }
    }
}