/**
* @File Name : ContactSoapService.cls
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

// A global class that exposes a method as a SOAP web service. 

// The 'global' keyword makes the class visible to all Apex code and the SOAP API. 

global class ContactSoapService {  

   

    // A wrapper class to structure the response for the SOAP service. 

    // The 'webService' keyword on the class and its members makes them accessible to the SOAP API. 

    global class ContactResponse {  

        // A webService field for the contact's Id. 

        webService String id;  

        // A webService field for the contact's first name. 

        webService String firstName;  

        // A webService field for the contact's last name. 

        webService String lastName;  

        // A webService field for the contact's email. 

        webService String email;  

        // A webService field for the contact's phone. 

        webService String phone;  

        // A webService field for the account Id associated with the contact. 

        webService String accountId;  

    }  

   

    // A web service method to retrieve a contact by their Id. 

    // The 'webService' and 'static' keywords are required for exposing a method as a SOAP endpoint. 

    // It takes a contactId as input and returns a ContactResponse object. 

    webService static ContactResponse getContactById(String contactId) {  

        // Create an instance of the wrapper class to hold the response data. 

        ContactResponse resp = new ContactResponse();  

        try {  

            // Query for the Contact record using the provided Id. 

            // A SOQL query is used to retrieve specific fields from the Contact object. 

            Contact c = [  

                SELECT Id, FirstName, LastName, Email, Phone, AccountId  

                FROM Contact  

                WHERE Id = :contactId  

                LIMIT 1  

            ];  

   

            // Populate the ContactResponse object with data from the queried Contact. 

            resp.id = String.valueOf(c.Id);  

            resp.firstName = c.FirstName;  

            resp.lastName = c.LastName;  

            resp.email = c.Email;  

            resp.phone = c.Phone;  

            resp.accountId = String.valueOf(c.AccountId);  

   

        } catch (Exception e) {  

            // Catch any exceptions that occur, such as if the contact is not found. 

            // Throwing a CalloutException results in a SOAP fault, which is a standard way to report errors in SOAP services. 

            throw new CalloutException('Contact not found or error: ' + e.getMessage());  

        }  

        // Return the populated ContactResponse object. 

        return resp;  

    }  

}