global with sharing class ClosedWonOpportunityBatch implements Database.Batchable<sObject>, Database.Stateful {
  
  global Date runDate;

  global ClosedWonOpportunityBatch() {
    this.runDate = Date.today(); // default; schedulers/test can pass alternative via constructor if needed
  }

  global ClosedWonOpportunityBatch(Date runDate) {
    this.runDate = runDate;
  }

  // Holds emails accumulated across execute chunks (Database.Stateful preserves this)
  global List<EmailHelper.EmailContent> pendingEmails = new List<EmailHelper.EmailContent>();

  global Database.QueryLocator start(Database.BatchableContext bc) {
    // Only accounts with primary email
    String q = 'SELECT Id, Name, Primary_Email__c FROM Account WHERE Primary_Email__c != NULL';
    return Database.getQueryLocator(q);
  }

  global void execute(Database.BatchableContext bc, List<Account> scope) {
    if (scope == null || scope.isEmpty()) {
      return;
    }

    Set<Id> acctIds = new Set<Id>();
    for (Account a : scope) {
      acctIds.add(a.Id);
    }
    
    if (acctIds.isEmpty()) {
      return;
    }

    // Bulk fetch opportunities for runDate with StageName = 'Closed Won'
    List<Opportunity> opps = [
      SELECT Id, Name, Amount, AccountId, CloseDate
      FROM Opportunity
      WHERE AccountId IN :acctIds
      AND StageName = 'Closed Won'
      AND CloseDate = :runDate
    ];

    Map<Id, List<Opportunity>> mapByAcc = new Map<Id, List<Opportunity>>();
    for (Opportunity o : opps) {
      if (!mapByAcc.containsKey(o.AccountId)) {
        mapByAcc.put(o.AccountId, new List<Opportunity>());
      }
      mapByAcc.get(o.AccountId).add(o);
    }

    // For each account in scope, build email content if there are opps
    // Use the class-level accumulator so finish() can send them
    if (pendingEmails == null) {
      pendingEmails = new List<EmailHelper.EmailContent>();
    }

    for (Account a : scope) {
      if (mapByAcc.containsKey(a.Id)) {
        // Corrected: The method name in EmailHelper is `buildClosedEmail`, not `buildClosedWonEmail`
        EmailHelper.EmailContent content = EmailHelper.buildClosedEmail(a, mapByAcc.get(a.Id), runDate);
        if (content != null) {
          pendingEmails.add(content);
        }
      }
    }

    // Do not send here; finish() will perform sending so all chunks are aggregated.
  }

  global void finish(Database.BatchableContext bc) {
    // Send accumulated emails. Wrap send calls to prevent whole batch failing on a single send error.
    if (pendingEmails == null || pendingEmails.isEmpty()) {
      System.debug('ClosedWonOpportunityBatch finished for date: ' + runDate + ' - no emails to send.');
      return;
    }
    
    for (EmailHelper.EmailContent e : pendingEmails) {
      try {
        if (e != null) {
          EmailHelper.sendEmail(e);
        }
      } catch (Exception ex) {
        // Log and continue sending remaining emails to avoid failing the finish method.
        System.debug('ClosedWonOpportunityBatch: error sending email for account/content - ' + ex.getMessage());
      }
    }
    
    System.debug('ClosedWonOpportunityBatch finished for date: ' + runDate + ' - emails sent: ' + pendingEmails.size());
  }
}