// global class OpportunityQuotePDFController {
global class OpportunityQuotePDFController {
    public Opportunity opp { get; private set; }
    public List<Quote> quotes { get; private set; }
    
    global OpportunityQuotePDFController(ApexPages.StandardController controller) {
        Id oppId = controller.getId();
        // Query Opportunity with Owner.Name
        opp = [
            SELECT Id, Name, Owner.Name
            FROM Opportunity
            WHERE Id = :oppId
            LIMIT 1
        ];

        // Query all Quotes related to the Opportunity with their QuoteLineItems
        quotes = [
            SELECT Id, QuoteNumber, CreatedDate, ExpirationDate, GrandTotal,
                BillingStreet, BillingCity, BillingState, BillingPostalCode, BillingCountry,
                ShippingStreet, ShippingCity, ShippingState, ShippingPostalCode, ShippingCountry,
                Contact.Name, Contact.Email,
                (SELECT Product2.ProductCode, Description, Quantity, ListPrice, UnitPrice,
                    TotalPrice
                 FROM QuoteLineItems)
            FROM Quote
            WHERE OpportunityId = :oppId
        ];
    }
}