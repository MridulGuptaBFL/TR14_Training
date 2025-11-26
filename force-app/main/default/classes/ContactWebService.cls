/**
* @File Name : ContactWebService.cls
* @Description :
* @Author :
* @Last Modified By :
* @Last Modified On : November 4, 2025
* @Modification Log :
*==============================================================================
* Ver | Date | Author | Modification
*==============================================================================
* 1.0 | November 4, 2025 |   | Initial Version
**/

global without sharing class ContactWebService {
 
    // Enhanced response wrapper with more details
    global class ContactResponse {
        webService String status;         // "SUCCESS" or "ERROR"
        webService String message;        // Detailed message
        webService String contactId;      // Return the ID for verification
        webService String contactName;
        webService String email;
        webService String phone;
        webService Boolean hasAccess;     // Check if user has access to contact
        webService Integer queryRows;     // Number of rows processed
    }
 
    // Web service method exposed as SOAP API
    webService static ContactResponse getContactDetails(String contactId) {
        ContactResponse response = new ContactResponse();
        response.contactId = contactId;
 
        try {
            // Edge Case 1: Null or empty input
            if (String.isBlank(contactId)) {
                response.status = 'ERROR';
                response.message = 'Contact Id cannot be null or empty.';
                return response;
            }
 
            // Edge Case 2: Trim whitespace
            contactId = contactId.trim();
            if (String.isBlank(contactId)) {
                response.status = 'ERROR';
                response.message = 'Contact Id contains only whitespace.';
                return response;
            }
 
            // Edge Case 3: Invalid Id format (not 15/18 chars)
            if (contactId.length() != 15 && contactId.length() != 18) {
                response.status = 'ERROR';
                response.message = 'Invalid Contact Id format. Expected 15 or 18 characters, got ' + contactId.length() + '.';
                return response;
            }
 
            // Edge Case 4: Check if it's a valid Salesforce ID pattern using Apex method
            Boolean isValidId = true;
            for (Integer i = 0; i < contactId.length(); i++) {
                String currentChar = contactId.substring(i, i + 1);
                if (!'abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789'.contains(currentChar)) {
                    isValidId = false;
                    break;
                }
            }
            
            if (!isValidId) {
                response.status = 'ERROR';
                response.message = 'Invalid Contact Id pattern. Contains special characters.';
                return response;
            }
 
            // Edge Case 5: Check if it's actually a Contact ID (starts with 003)
            if (!contactId.startsWith('003')) {
                response.status = 'ERROR';
                response.message = 'Invalid object type. ID must be for a Contact (should start with 003).';
                return response;
            }
 
            // Edge Case 6: Check governor limits before query
            if (Limits.getLimitQueries() - Limits.getQueries() == 0) {
                response.status = 'ERROR';
                response.message = 'SOQL query limit reached. Cannot process request.';
                return response;
            }
 
            // Try to fetch Contact with field-level security check
            List<Contact> contacts = [
                SELECT Id, Name, Email, Phone, IsDeleted
                FROM Contact 
                WHERE Id = :contactId 
                AND IsDeleted = false
                LIMIT 1
            ];
 
            // Edge Case 7: Contact not found
            if (contacts.isEmpty()) {
                response.status = 'ERROR';
                response.message = 'No active contact found for the given Id. Contact may be deleted or not exist.';
                return response;
            }
 
            Contact con = contacts[0];
            response.queryRows = contacts.size();
 
            // Edge Case 8: Check field accessibility
            response.hasAccess = true;
            
            // Edge Case 9: Handle null field values
            response.status = 'SUCCESS';
            response.message = 'Contact retrieved successfully.';
            response.contactName = String.isNotBlank(con.Name) ? con.Name : 'No Name';
            response.email = String.isNotBlank(con.Email) ? con.Email : 'No Email';
            response.phone = String.isNotBlank(con.Phone) ? con.Phone : 'No Phone';
 
            // Edge Case 10: Check response size (SOAP has limits)
            String responseSize = JSON.serialize(response);
            if (responseSize.length() > 3000000) { // 3MB rough limit
                response.status = 'WARNING';
                response.message += ' Response size approaching limits.';
            }
 
        } catch (System.QueryException e) {
            // Edge Case 11: Specific query exceptions
            if (e.getMessage().contains('List has no rows')) {
                response.status = 'ERROR';
                response.message = 'No contact found for the given Id.';
            } else if (e.getMessage().contains('sObject type')) {
                response.status = 'ERROR';
                response.message = 'Invalid object type. ID must be for a Contact.';
            } else {
                response.status = 'ERROR';
                response.message = 'Query exception: ' + e.getMessage();
            }
        } catch (System.SecurityException e) {
            // Edge Case 12: Security/access violations
            response.status = 'ERROR';
            response.message = 'Access denied. Insufficient permissions to read Contact.';
        } catch (System.LimitException e) {
            // Edge Case 13: Governor limits exceeded
            response.status = 'ERROR';
            response.message = 'Organization limits exceeded: ' + e.getMessage();
        } catch (Exception e) {
            // Edge Case 14: Any other unexpected exception
            response.status = 'ERROR';
            response.message = 'Unexpected system error: ' + e.getMessage() + '. Please contact administrator.';
        }
 
        // Edge Case 15: Final validation - ensure we always return a valid response
        if (response.status == null) {
            response.status = 'UNKNOWN';
            response.message = 'Unexpected processing state.';
        }
 
        return response;
    }
 
    // Additional method: Bulk contact retrieval with limits check
    webService static List<ContactResponse> getMultipleContacts(List<String> contactIds) {
        List<ContactResponse> responses = new List<ContactResponse>();
        
        // Edge Case 16: Bulk operations limit
        if (contactIds == null || contactIds.size() > 10) {
            ContactResponse errorResponse = new ContactResponse();
            errorResponse.status = 'ERROR';
            errorResponse.message = 'Maximum 10 contacts allowed per request.';
            responses.add(errorResponse);
            return responses;
        }
 
        for (String contactId : contactIds) {
            responses.add(getContactDetails(contactId));
        }
 
        return responses;
    }
}