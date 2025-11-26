public with sharing class InvoiceController {
    public Id orderId { get; private set; }
    public Order OrderRec { get; private set; }
    public List<InvoiceLineWrapper> OrderItems { get; private set; }
    public String InvoiceNumber { get; private set; }
    public String PrimaryContactName { get; private set; }
    public Date InvoiceDate { get; private set; }
    public String StoreName { get { return 'Blush'; } }
    public String StoreAddress { get { return 'Store Address Line1<br/>Pune, Maharashtra, 411045'; } }

    public String BillingAddressHtml { get; private set; }
    public String ShippingAddressHtml { get; private set; }

    public Decimal TotalTaxable { get; private set; }
    public Decimal TotalCGST { get; private set; }
    public Decimal TotalSGST { get; private set; }
    public Decimal TotalIGST { get; private set; }
    public Decimal SubTotal { get; private set; }
    public Decimal TotalPayable { get; private set; }

    // VF-friendly formatted strings (no format functions called from VF)
    public String getSubTotalFmt()     { return String.valueOf(round2(SubTotal)); }
    public String getTotalCGSTFmt()    { return String.valueOf(round2(TotalCGST)); }
    public String getTotalSGSTFmt()    { return String.valueOf(round2(TotalSGST)); }
    public String getTotalIGSTFmt()    { return String.valueOf(round2(TotalIGST)); }
    public String getTotalPayableFmt() { return String.valueOf(round2(TotalPayable)); }

    public Boolean AnyDiscountAbove10Pct { get; private set; }

    public InvoiceController() {
        orderId = ApexPages.currentPage().getParameters().get('id');
        if (orderId == null) return;
        loadOrder();
    }

    private void loadOrder() {
        // NOTE: adapt field API names if your org uses different ones
        OrderRec = [SELECT Id, Owner.Name, Name, OrderNumber, BillingState, Payment_Mode__c,
                           Total_Net_Price__c, Total_CGST__c, Total_SGST__c, Total_IGST__c, Taxes__c, Amount_Payable__c,
                           AccountId, Account.Name, Account.BillingStreet, Account.BillingCity, Account.BillingState, Account.BillingPostalCode,
                           ShippingStreet, ShippingCity, ShippingState, ShippingPostalCode
                    FROM Order
                    WHERE Id = :orderId
                    LIMIT 1];

        InvoiceNumber = (String.isBlank(OrderRec.OrderNumber) ? OrderRec.Name : OrderRec.OrderNumber);
        InvoiceDate = Date.today();

        // primary contact
        List<Contact> contacts = [SELECT Id, FirstName, LastName FROM Contact WHERE AccountId = :OrderRec.AccountId LIMIT 1];
        PrimaryContactName = (contacts.isEmpty() ? '' : ((contacts[0].FirstName == null ? '' : contacts[0].FirstName + ' ') + (contacts[0].LastName == null ? '' : contacts[0].LastName))).trim();

        BillingAddressHtml = buildAddressHtml(
            OrderRec.Account != null ? OrderRec.Account.Name : '',
            OrderRec.Account != null ? OrderRec.Account.BillingStreet : '',
            OrderRec.Account != null ? OrderRec.Account.BillingCity : '',
            OrderRec.Account != null ? OrderRec.Account.BillingState : '',
            OrderRec.Account != null ? OrderRec.Account.BillingPostalCode : ''
        );

        String shipStreet = isBlank(OrderRec.ShippingStreet) ? (OrderRec.Account != null ? OrderRec.Account.BillingStreet : '') : OrderRec.ShippingStreet;
        String shipCity   = isBlank(OrderRec.ShippingCity) ? (OrderRec.Account != null ? OrderRec.Account.BillingCity : '') : OrderRec.ShippingCity;
        String shipState  = isBlank(OrderRec.ShippingState) ? (OrderRec.Account != null ? OrderRec.Account.BillingState : '') : OrderRec.ShippingState;
        String shipPostal = isBlank(OrderRec.ShippingPostalCode) ? (OrderRec.Account != null ? OrderRec.Account.BillingPostalCode : '') : OrderRec.ShippingPostalCode;

        ShippingAddressHtml = buildAddressHtml(null, shipStreet, shipCity, shipState, shipPostal);

        // Query items (standard OrderItem with Product2 relationship). Adapt field API names if you use custom OrderItem object
        List<OrderItem> rawItems = [SELECT Id, Product2Id, Product2.Name, Product2.ProductCode,
                                         UnitPrice, Quantity, Discount__c, Net_Price__c, CGST__c, SGST__c, IGST__c, Product_Category__c
                                  FROM OrderItem
                                  WHERE OrderId = :orderId
                                  ORDER BY CreatedDate ASC];

        OrderItems = new List<InvoiceLineWrapper>();
        TotalTaxable = 0;
        TotalCGST = 0;
        TotalSGST = 0;
        TotalIGST = 0;
        SubTotal = 0;
        TotalPayable = 0;
        AnyDiscountAbove10Pct = false;

        Boolean isInterState = OrderRec.BillingState == null ? true : (OrderRec.BillingState != 'MH');

        for (OrderItem oi : rawItems) {
            // wrap and compute GST logic per rules
            InvoiceLineWrapper w = new InvoiceLineWrapper(oi, isInterState);
            OrderItems.add(w);

            TotalTaxable += w.Taxable;
            TotalCGST += w.CGST;
            TotalSGST += w.SGST;
            TotalIGST += w.IGST;
            SubTotal += (w.UnitPrice * w.Quantity) - (w.Discount * w.Quantity);
            TotalPayable += w.NetPrice;

            if (w.DiscountPercent > 10) AnyDiscountAbove10Pct = true;
        }

        // Round to 2 decimals
        TotalTaxable = round2(TotalTaxable);
        TotalCGST = round2(TotalCGST);
        TotalSGST = round2(TotalSGST);
        TotalIGST = round2(TotalIGST);
        SubTotal = round2(SubTotal);
        TotalPayable = round2(TotalPayable);
    }

    // Helper to build address html
    private String buildAddressHtml(String nameOrNull, String street, String city, String state, String postal) {
        List<String> parts = new List<String>();
        if (nameOrNull != null && nameOrNull != '') parts.add(nameOrNull);
        if (!isBlank(street)) parts.add(street);
        String cityStateZip = '';
        if (!isBlank(city)) cityStateZip += city;
        if (!isBlank(state)) {
            if (!String.isEmpty(cityStateZip)) cityStateZip += ', ';
            cityStateZip += state;
        }
        if (!isBlank(postal)) {
            if (!String.isEmpty(cityStateZip)) cityStateZip += ' - ';
            cityStateZip += postal;
        }
        if (!String.isEmpty(cityStateZip)) parts.add(cityStateZip);
        return parts.isEmpty() ? '' : String.join(parts, '<br/>');
    }

    private Boolean isBlank(String s) { return s == null || String.valueOf(s).trim().length() == 0; }

    // keep round2 static so wrapper can call it
    public static Decimal round2(Decimal d) {
        if (d == null) return 0;
        return d.setScale(2, RoundingMode.HALF_UP);
    }

    // Wrapper class - computes taxes according to rules; Discount__c is treated as percentage field
    public class InvoiceLineWrapper {
        public Id Id { get; private set; }
        public String ProductCode { get; private set; }
        public String ProductName { get; private set; }
        public Decimal Quantity { get; private set; }
        public Decimal UnitPrice { get; private set; }
        public Decimal Discount { get; private set; } // absolute per unit discount (calculated from percent)
        public Decimal DiscountPercent { get; private set; } // percent (from Discount__c)
        public Decimal Taxable { get; private set; }
        public Decimal CGST { get; private set; }
        public Decimal SGST { get; private set; }
        public Decimal IGST { get; private set; }
        public Decimal NetPrice { get; private set; }
        public String ProductCategory { get; private set; }

        public InvoiceLineWrapper(OrderItem oi, Boolean isInterState) {
            this.Id = oi.Id;
            this.ProductCode = oi.Product2 != null ? oi.Product2.ProductCode : '';
            this.ProductName = oi.Product2 != null ? oi.Product2.Name : '';
            this.Quantity = oi.Quantity == null ? 0 : oi.Quantity;
            this.UnitPrice = oi.UnitPrice == null ? 0 : oi.UnitPrice;

            // Discount__c is percentage in this org (e.g. 10 => 10%)
            this.DiscountPercent = oi.Discount__c == null ? 0 : oi.Discount__c;
            // compute per-unit absolute discount
            this.Discount = InvoiceController.round2(this.UnitPrice * (this.DiscountPercent / 100));

            this.ProductCategory = oi.Product_Category__c;

            // Taxable = (UnitPrice - Discount) * Quantity
            this.Taxable = (this.UnitPrice - this.Discount) * this.Quantity;
            if (this.Taxable < 0) this.Taxable = 0;

            // Determine GST rate according to rules:
            Decimal gstRate = 0;
            if (this.ProductCategory == 'Garments') {
                // if garments amount (unitPrice*quantity) greater than 1000 => 12% else 5%
                Decimal amount = this.UnitPrice * this.Quantity;
                gstRate = amount > 1000 ? 12 : 5;
            } else if (this.ProductCategory == 'Jewellery') {
                gstRate = 3;
            } else {
                gstRate = 0;
            }

            if (isInterState) {
                this.IGST = InvoiceController.round2((this.Taxable * gstRate) / 100);
                this.CGST = 0;
                this.SGST = 0;
            } else {
                Decimal halfRate = gstRate / 2;
                this.CGST = InvoiceController.round2((this.Taxable * halfRate) / 100);
                this.SGST = InvoiceController.round2((this.Taxable * halfRate) / 100);
                this.IGST = 0;
            }

            // Net price line-level
            this.NetPrice = InvoiceController.round2(this.Taxable + this.CGST + this.SGST + this.IGST);

            // prefer stored Net_Price__c if provided (but keep calculation otherwise)
            if (oi.Net_Price__c != null) {
                this.NetPrice = InvoiceController.round2(oi.Net_Price__c);
            }

            // prefer stored CGST/SGST/IGST fields if they are present and non-null
            if (oi.CGST__c != null) this.CGST = InvoiceController.round2(oi.CGST__c);
            if (oi.SGST__c != null) this.SGST = InvoiceController.round2(oi.SGST__c);
            if (oi.IGST__c != null) this.IGST = InvoiceController.round2(oi.IGST__c);

            // Recompute NetPrice after preferring stored taxes
            this.NetPrice = InvoiceController.round2(this.Taxable + this.CGST + this.SGST + this.IGST);
        }

        // VF-friendly formatted getters (return strings, no external format method)
        public String getFmtUnitPrice() { return String.valueOf(InvoiceController.round2(this.UnitPrice)); }
        public String getFmtDiscount()  { return String.valueOf(InvoiceController.round2(this.Discount)); }
        public String getFmtTaxable()   { return String.valueOf(InvoiceController.round2(this.Taxable)); }
        public String getFmtCGST()      { return String.valueOf(InvoiceController.round2(this.CGST)); }
        public String getFmtSGST()      { return String.valueOf(InvoiceController.round2(this.SGST)); }
        public String getFmtIGST()      { return String.valueOf(InvoiceController.round2(this.IGST)); }
        public String getFmtNetPrice()  { return String.valueOf(InvoiceController.round2(this.NetPrice)); }
    }
}