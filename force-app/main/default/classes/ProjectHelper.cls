public class ProjectHelper { //Question 1 of Collections
    
    public class AuraHandledException extends Exception {}
    // 1. Get Members by Project Name
    public static void getMembers(String projectName) {

        List<Project__c> projects = [SELECT Id, Name FROM Project__c WHERE Name = :projectName];
        if(projects.size() == 0) {
            throw new AuraHandledException('No project with matching name found');
        }
        if(projects.size() > 1){
            throw new AuraHandledException('Multiple projects with matching name found');
        }
        Project__c proj = projects[0];
        
        List<Project_Member__c> members = [
            SELECT Member__c, Name
            FROM Project_Member__c
            WHERE Project__c = :proj.Id  AND IsActive__c = true 
        ];
        
        List<Map<String, Object>> result = new List<Map<String, Object>>();
        for(Project_Member__c m : members) {
            Map<String, Object> memberInfo = new Map<String, Object>();
            memberInfo.put('Member', m.Member__c);
            memberInfo.put('Name', m.Name);
            result.add(memberInfo);
        }
        System.debug('Members: ' + result);
    }
    
    // 2. Get member details by Member Id
    public static void getMemberDetails(Id memberId) {
        List<Project_Member__c> members = [SELECT Id, Name FROM Project_Member__c WHERE Id = :memberId LIMIT 1];
        if(members.isEmpty()) {
            System.debug('Member not found');
            return;
        }
        System.debug('Member Details: ' + members[0]);
    }
    
    // 3. Get total sales by Sales Rep name in date range
    public static void getTotalSales(Date startDate, Date endDate) {
        AggregateResult[] aggResults = [
            SELECT Owner.Name ownerName, SUM(Amount__c) totalSales
            FROM Opportunity
            WHERE CloseDate >= :startDate AND CloseDate <= :endDate
            GROUP BY Owner.Name
        ];
        
        Map<String, Decimal> salesMap = new Map<String, Decimal>();
        for(AggregateResult ar : aggResults) {
            String salesRep = (String) ar.get('ownerName');
            Decimal totalSale = (Decimal) ar.get('totalSales');
            salesMap.put(salesRep, totalSale);
        }
        System.debug('Total Sales: ' + salesMap);
    }
}
/*
ProjectHelper.getMembers('Project X');
ProjectHelper.getMemberDetails('a01xx0000001AAA');
ProjectHelper.getTotalSales(Date.newInstance(2025, 1, 1), Date.newInstance(2025, 12, 31));
*/