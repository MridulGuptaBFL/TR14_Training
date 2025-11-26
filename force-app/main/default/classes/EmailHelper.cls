public with sharing class EmailHelper {
  
  public class EmailContent {
    public String subject;
    public String body;
    public List<String> toAddresses;
    
    public EmailContent(String subject, String body, List<String> toAddresses) {
      this.subject = subject;
      this.body = body;
      this.toAddresses = toAddresses;
    }
  }
  
  public static void sendEmail(EmailContent content) {
    if (content == null || content.toAddresses == null || content.toAddresses.isEmpty()) {
      System.debug('Email send aborted: Invalid content or empty recipient list.');
      return;
    }
    
    Messaging.SingleEmailMessage mail = new Messaging.SingleEmailMessage();
    mail.setToAddresses(content.toAddresses);
    mail.setSubject(content.subject);
    mail.setPlainTextBody(content.body);
    
    // Respect email limits: 5K emails per day for org; ensure this is acceptable for your org size.
    try {
      Messaging.sendEmail(new List<Messaging.SingleEmailMessage>{mail});
    } catch (Exception ex) {
      // Log the error for review. You may want to use a custom logging framework.
      System.debug(LoggingLevel.ERROR, 'Email send failed: ' + ex.getMessage());
    }
  }
  
  public static EmailContent buildClosedEmail(Account acc, List<Opportunity> opps, Date forDate) {
    // Corrected method signature: public static EmailContent
    
    if (acc == null || opps == null || opps.isEmpty()) {
      return null;
    }
    
    Decimal totalAmount = 0;
    String body = 'Hello ' + (acc.Name != null ? acc.Name : '') + ',\n\nHere are your Closed Won Opportunities for ' + forDate.format() + ':\n\n';
    
    for (Opportunity o : opps) {
      body += '- ' + o.Name + ' — Amount: ' + (o.Amount == null ? '0' : String.valueOf(o.Amount)) + '\n';
      totalAmount += (o.Amount == null ? 0 : o.Amount);
    }
    
    body += '\nTotal Amount: ' + String.valueOf(totalAmount) + '\n\nRegards,\nSalesforce';
    String subject = 'Closed Won Opportunities: ' + forDate.format();
    
    // Check for the custom field Primary_Email__c before trying to access it.
    // It's a best practice to query for required fields and handle cases where they might be null or missing.
    if (acc.Primary_Email__c == null) {
      System.debug(LoggingLevel.WARN, 'Primary_Email__c field is null for Account: ' + acc.Name + '. Cannot build email.');
      return null;
    }
    
    return new EmailContent(subject, body, new List<String>{ acc.Primary_Email__c });
  }
}