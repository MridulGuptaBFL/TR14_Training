/**
* @File Name : ClosedWonOpportunitiesBatch.cls
* @Description :
* @Author :
* @Last Modified By :
* @Last Modified On : October 13, 2025
* @Modification Log :
*==============================================================================
* Ver | Date | Author | Modification
*==============================================================================
* 1.0 | October 13, 2025 |   | Initial Version
**/

// Batch class to collect closed won opportunities and send emails
global class ClosedWonOpportunitiesBatch implements Database.Batchable<SObject>, Database.Stateful {
    // Store map of Account Id to email body content for aggregation
    Map<Id, List<String>> accountToOppLines = new Map<Id, List<String>>();
    Map<Id, Decimal> accountToTotalAmount = new Map<Id, Decimal>();
    Map<Id, String> accountEmails = new Map<Id, String>();

    // Daily date to query Closed Won opportunities for that date
    Date batchDate;

    global ClosedWonOpportunitiesBatch() {
        batchDate = Date.today().addDays(-1); // Yesterday date as batch runs at midnight
    }

    global Database.QueryLocator start(Database.BatchableContext bc) {
        // Query all closed won opportunities that changed to closed won yesterday
        String query = 'SELECT Id, Name, Amount, AccountId, Account.OwnerId.Email ' +
                       'FROM Opportunity ' + 
                       'WHERE StageName = \'Closed Won\' AND CloseDate = :batchDate';

        return Database.getQueryLocator(query);
    }

    global void execute(Database.BatchableContext bc, List<Opportunity> scope) {
        for (Opportunity opp : scope) {
            // Initialize list and total amount per account
            if (!accountToOppLines.containsKey(opp.AccountId)) {
                accountToOppLines.put(opp.AccountId, new List<String>());
                accountToTotalAmount.put(opp.AccountId, 0);
                accountEmails.put(opp.AccountId, opp.Account.OwnerId.Email);
            }
            // Add opportunity line info
            accountToOppLines.get(opp.AccountId).add(opp.Name + ' - Amount: ' + String.valueOf(opp.Amount));
            // Aggregate total amount
            accountToTotalAmount.put(opp.AccountId, accountToTotalAmount.get(opp.AccountId) + opp.Amount);
        }
    }

    global void finish(Database.BatchableContext bc) {
        // Send email for each Account with collected closed won opps details
        List<Messaging.MassEmailMessage> emails = new List<Messaging.MassEmailMessage>();

        for (Id accountId : accountToOppLines.keySet()) {
            String toEmail = accountEmails.get(accountId);
            if (toEmail == null || toEmail == '') {
                // Skip if no primary email is available
                continue;
            }
            String body = 'Closed Won Opportunities for ' + batchDate.format() + ':\n\n';
            for (String line : accountToOppLines.get(accountId)) {
                body += line + '\n';
            }
            body += '\nTotal Amount: ' + String.valueOf(accountToTotalAmount.get(accountId));

            Messaging.SingleEmailMessage mail = new Messaging.SingleEmailMessage();
            mail.setToAddresses(new String[] { toEmail });
            mail.setSubject('Daily Closed Won Opportunities Summary');
            mail.setPlainTextBody(body);
            Messaging.sendEmail(new Messaging.SingleEmailMessage[] { mail });
        }
    }
}

// Scheduled Apex class to run batch daily at midnight
// global class ClosedWonOpportunitiesScheduler implements Schedulable {
//     global void execute(SchedulableContext sc) {
//         ClosedWonOpportunitiesBatch batch = new ClosedWonOpportunitiesBatch();
//         Database.executeBatch(batch, 200);
//     }
// }


//Usage:
//Deploy the batch and scheduler classes.
//Schedule the batch via Salesforce UI or using the following anonymous Apex:

// String cron = '0 0 0 * * ?'; // Every day at midnight
// ClosedWonOpportunitiesScheduler scheduler = new ClosedWonOpportunitiesScheduler();
// System.schedule('Daily Closed Won Opps Batch', cron, scheduler);