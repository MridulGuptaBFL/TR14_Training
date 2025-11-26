/**
 * OrderHistoryController
 *
 * Controller used by the OrderHistory LWC to:
 *  - return Accounts which are flagged as isCustomerUser__c = true
 *  - return paginated orders for a selected account filtered by period, status and search term
 *
 * Best practices: bulk-friendly SOQL, explicit field lists, wrapper DTO for LWC consumption.
 */
public with sharing class OrderHistoryController {
    
    public class OrderDTO {
        @AuraEnabled public Id orderId;
        @AuraEnabled public String orderNumber;
        @AuraEnabled public Date orderDate;
        @AuraEnabled public String orderStatus;
        @AuraEnabled public Id accountId;
        @AuraEnabled public String accountName;
        
        public OrderDTO(Order o){
            this.orderId = o.Id;
            this.orderNumber = o.OrderNumber;
            this.orderDate = o.EffectiveDate;
            this.orderStatus = o.Status;
            this.accountId = o.AccountId;
            this.accountName = (o.Account != null) ? o.Account.Name : null;
        }
    }
    
    /**
     * Get all Accounts which have isCustomerUser__c = true so they are selectable.
     * @return list of Accounts (Id, Name, isCustomerUser__c)
     */
    @AuraEnabled(cacheable=true)
    public static List<Account> getCustomerAccounts(){
        return [
            SELECT Id, Name, isCustomerUser__c
            FROM Account
            WHERE isCustomerUser__c = true
            ORDER BY Name
        ];
    }
    
    /**
     * Get all Accounts in the org for populating the Account picklist.
     * @return list of Accounts (Id, Name, isCustomerUser__c)
     */
    @AuraEnabled(cacheable=true)
    public static List<Account> getAllAccounts(){
        return [
            SELECT Id, Name, isCustomerUser__c
            FROM Account
            ORDER BY Name
        ];
    }
    
    /**
     * Fetch paginated orders for the LWC.
     *
     * @param accountId - selected Account Id (nullable)
     * @param periodMonths - number of months for the 'Period' filter (nullable). Allowed: 3,6,9,12
     * @param status - Order status filter (nullable)
     * @param searchTerm - search filter applied to OrderNumber and Status (nullable)
     * @param pageNumber - 1-based page number
     * @param pageSize - number of records per page
     *
     * @return Map with keys:
     *   records => List<OrderDTO> (the page of orders)
     *   totalSize => Integer (total number of matching orders)
     */
    @AuraEnabled(cacheable=true)
    public static Map<String, Object> fetchOrders(
        String accountIdStr, 
        String periodMonthsStr,
        String status,
        String searchTerm,
        String pageNumberStr,
        String pageSizeStr
    ) {
        // Parse parameters
        Id accountId = null;
        if (accountIdStr != null && accountIdStr.trim().length() > 0){
            accountId = Id.valueOf(accountIdStr);
        }
        Integer periodMonths = null;
        if (periodMonthsStr != null && periodMonthsStr.trim().length() > 0){
            periodMonths = Integer.valueOf(periodMonthsStr);
        }
        Integer pageNumber = Integer.valueOf(pageNumberStr ?? '1');
        Integer pageSize = Integer.valueOf(pageSizeStr ?? '5');
        
        if (pageNumber < 1) pageNumber = 1;
        if (pageSize < 1) pageSize = 5;
        
        // Build WHERE clause conditions
        List<String> whereConditions = new List<String>();
        whereConditions.add('AccountId != null');
        
        if (accountId != null){
            whereConditions.add('AccountId = :accountId');
        }
        
        if (periodMonths != null && periodMonths > 0){
            Date fromDate = Date.today().addMonths(-periodMonths);
            whereConditions.add('EffectiveDate >= :fromDate');
        }
        
        if (status != null && status.trim().length() > 0){
            whereConditions.add('Status = :status');
        }
        
        String searchLike = null;
        if (searchTerm != null && searchTerm.trim().length() > 0){
            searchLike = '%' + searchTerm + '%';
            whereConditions.add('(OrderNumber LIKE :searchLike OR Status LIKE :searchLike)');
        }
        
        // Combine WHERE conditions
        String whereClause = String.join(whereConditions, ' AND ');
        
        // Count total matching records
        String countQuery = 'SELECT COUNT() FROM Order WHERE ' + whereClause;
        Integer totalSize = Database.countQuery(countQuery);
        
        // Fetch paginated records
        Integer offset = (pageNumber - 1) * pageSize;
        String selectQuery = 'SELECT Id, OrderNumber, EffectiveDate, Status, AccountId, Account.Name ' +
                           'FROM Order WHERE ' + whereClause + 
                           ' ORDER BY EffectiveDate DESC LIMIT :pageSize OFFSET :offset';
        
        List<Order> orders = Database.query(selectQuery);
        
        // Convert to DTOs
        List<OrderDTO> dtos = new List<OrderDTO>();
        for (Order o : orders){
            dtos.add(new OrderDTO(o));
        }
        
        Map<String, Object> result = new Map<String, Object>();
        result.put('records', dtos);
        result.put('totalSize', totalSize);
        result.put('pageNumber', pageNumber);
        result.put('pageSize', pageSize);
        return result;
    }
}