public with sharing class TopQuarterlyOpportunitiesController {
    @AuraEnabled(cacheable=true)
    public static List<String> getTopQuarterlyOpportunities() {
        List<Opportunity> opps = [
            SELECT Name FROM Opportunity
            WHERE CreatedById = :UserInfo.getUserId()
            AND CreatedDate = THIS_QUARTER
            ORDER BY Amount DESC
            LIMIT 5
        ];
       List<String> oppNames = new List<String>();
        for (Opportunity o : opps) {
            oppNames.add(o.Name);
        }
        return oppNames;
    }
}