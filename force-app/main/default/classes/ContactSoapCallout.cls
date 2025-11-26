public with sharing class ContactSoapCallout {
 
    private static final String LOGIN_ENDPOINT  = 'https://login.salesforce.com/services/Soap/u/64.0';
    private static final String SERVICE_ENDPOINT =
        'https://orgfarm-c2dd184f35-dev-ed.develop.my.salesforce.com/services/Soap/class/ContactWebService';
 
    public class ContactResponse {
        public String contactId;
        public String contactName;
        public String email;
        public String phone;
        public String message;
        public String status;
        public Boolean hasAccess;
        public Integer queryRows;
    }
 
    public static ContactResponse callContactWebService(String contactId) {
        try {
            // Login to Org A
            HttpRequest loginReq = new HttpRequest();
            loginReq.setEndpoint(LOGIN_ENDPOINT);
            loginReq.setMethod('POST');
            loginReq.setHeader('Content-Type', 'text/xml; charset=UTF-8');
            loginReq.setHeader('SOAPAction', '""');
 
            String loginEnvelope =
                '<?xml version="1.0" encoding="utf-8"?>' +
                '<env:Envelope xmlns:xsd="http://www.w3.org/2001/XMLSchema" ' +
                'xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" ' +
                'xmlns:env="http://schemas.xmlsoap.org/soap/envelope/">' +
                '<env:Body>' +
                '<n1:login xmlns:n1="urn:partner.soap.sforce.com">' +
                '<n1:username>' + 'mridul.gupta665@agentforce.com' + '</n1:username>' +
                '<n1:password>' + 'Mridul.Gupta12ESafhdWDoPVJ1Ue6dtga9sKR' + '</n1:password>' +
                '</n1:login>' +
                '</env:Body>' +
                '</env:Envelope>';
 
            loginReq.setBody(loginEnvelope);
 
            Http http = new Http();
            HttpResponse loginRes = http.send(loginReq);
 
            if (loginRes.getStatusCode() != 200)
                throw new CalloutException('Login failed: ' + loginRes.getBody());
 
            //️Parse sessionId dynamically (namespace independent)
            String sessionId;
            Dom.Document loginDoc = new Dom.Document();
            loginDoc.load(loginRes.getBody());
            Dom.XMLNode envelope = loginDoc.getRootElement();
 
            for (Dom.XMLNode child : envelope.getChildElements()) {
                if (child.getName().toLowerCase().contains('body')) {
                    for (Dom.XMLNode grand : child.getChildElements()) {
                        if (grand.getName().toLowerCase().contains('loginresponse')) {
                            for (Dom.XMLNode node : grand.getChildElements()) {
                                if (node.getName().toLowerCase().contains('result')) {
                                    for (Dom.XMLNode n : node.getChildElements()) {
                                        if (n.getName().toLowerCase().contains('sessionid')) {
                                            sessionId = n.getText();
                                            break;
                                        }
                                    }
                                }
                            }
                        }
                    }
                }
            }
 
            if (String.isBlank(sessionId))
                throw new CalloutException('SessionId not found in login response: ' + loginRes.getBody());
 
            System.debug('SessionId fetched: ' + sessionId);
 
            //  Call the ContactWebService
            HttpRequest req = new HttpRequest();
            req.setEndpoint(SERVICE_ENDPOINT);
            req.setMethod('POST');
            req.setHeader('Content-Type', 'text/xml; charset=UTF-8');
            req.setHeader('SOAPAction', 'getContactDetails');
 
            String soapEnvelope =
                '<?xml version="1.0" encoding="utf-8"?>' +
                '<env:Envelope xmlns:xsd="http://www.w3.org/2001/XMLSchema" ' +
                'xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" ' +
                'xmlns:env="http://schemas.xmlsoap.org/soap/envelope/">' +
                '<env:Header>' +
                '<SessionHeader xmlns="http://soap.sforce.com/schemas/class/ContactWebService">' +
                '<sessionId>' + sessionId + '</sessionId>' +
                '</SessionHeader>' +
                '</env:Header>' +
                '<env:Body>' +
                '<getContactDetails xmlns="http://soap.sforce.com/schemas/class/ContactWebService">' +
                '<contactId>' + contactId + '</contactId>' +
                '</getContactDetails>' +
                '</env:Body>' +
                '</env:Envelope>';
 
            req.setBody(soapEnvelope);
 
            HttpResponse res = http.send(req);
            if (res.getStatusCode() != 200)
                throw new CalloutException('Service call failed: ' + res.getBody());
 
            // Parse the response safely (no null refs)
            ContactResponse cr = new ContactResponse();
 
            Dom.Document resDoc = new Dom.Document();
            resDoc.load(res.getBody());
            Dom.XMLNode envNode = resDoc.getRootElement();
            Dom.XMLNode bodyNode;
            for (Dom.XMLNode child : envNode.getChildElements()) {
                if (child.getName().toLowerCase().contains('body')) {
                    bodyNode = child;
                    break;
                }
            }
 
            if (bodyNode == null)
                throw new CalloutException('No Body node found in Contact response.');
 
            Dom.XMLNode resultNode;
            for (Dom.XMLNode n : bodyNode.getChildElements()) {
                if (n.getName().toLowerCase().contains('getcontactdetailsresponse')) {
                    for (Dom.XMLNode innerNode : n.getChildElements()) {  // renamed here
                        if (innerNode.getName().toLowerCase().contains('result')) {
                            resultNode = innerNode;
                            break;
                        }
                    }
                }
            }
 
            if (resultNode == null)
                throw new CalloutException('No result node found in Contact response: ' + res.getBody());
 
            for (Dom.XMLNode field : resultNode.getChildElements()) {
                String name = field.getName().toLowerCase();
                String val = field.getText();
                if (name.contains('contactid')) cr.contactId = val;
                else if (name.contains('contactname')) cr.contactName = val;
                else if (name.contains('email')) cr.email = val;
                else if (name.contains('phone')) cr.phone = val;
                else if (name.contains('message')) cr.message = val;
                else if (name.contains('status')) cr.status = val;
                else if (name.contains('hasaccess')) cr.hasAccess = (val == 'true');
                else if (name.contains('queryrows')) cr.queryRows = Integer.valueOf(val);
            }
 
            System.debug('Structured Response: ' + JSON.serializePretty(cr));
            return cr;
 
        } catch (Exception e) {
            System.debug('Error: ' + e.getMessage());
            return null;
        }
    }
}
/*ContactSoapCallout.ContactResponse result =
    ContactSoapCallout.callContactWebService('003gL00000DtYmMQAV');
System.debug(JSON.serializePretty(result));*/