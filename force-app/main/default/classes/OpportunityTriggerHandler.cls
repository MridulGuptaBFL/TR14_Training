public class OpportunityTriggerHandler {

    @future
    public static void updateAccountPointsAsync(Set<Id> accountIds) {
        List<Account> accountsToUpdate = new List<Account>();

        // Query Accounts and their related Opportunities.
        List<Account> accountsWithOpps = [
            SELECT Id, Points__c,
                   (SELECT Id, StageName FROM Opportunities WHERE StageName != 'Closed Lost') 
            FROM Account 
            WHERE Id IN :accountIds
        ];
        
        for (Account acc : accountsWithOpps) {
            Integer totalPoints = 0;
            Integer closedWonCount = 0;
            
            // First, count all non-Closed Lost opportunities and identify Closed Won ones.
            List<Opportunity> nonClosedLostOpps = new List<Opportunity>();
            for (Opportunity opp : acc.Opportunities) {
                nonClosedLostOpps.add(opp);
                if (opp.StageName == 'Closed Won') {
                    closedWonCount++;
                }
            }

            // Apply point logic to the filtered list
            for (Opportunity opp : nonClosedLostOpps) {
                totalPoints += 1;
                
                // Add an extra point for Closed Won if the total count is over 5
                if (closedWonCount > 5 && opp.StageName == 'Closed Won') {
                    totalPoints += 1;
                }
            }
            
            // Only update if points have changed
            if (acc.Points__c != totalPoints) {
                acc.Points__c = totalPoints;
                accountsToUpdate.add(acc);
            }
        }

        if (!accountsToUpdate.isEmpty()) {
            update accountsToUpdate;
        }
    }
}