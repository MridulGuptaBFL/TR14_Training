import { LightningElement, api, track } from "lwc";
export default class AccountReadOnlyForm extends LightningElement {
  @api recordId;
  // Fields to display in read-only form
  @track fields = [
    "Name",
    "AccountNumber",
    "Phone",
    "Website",
    "Industry",
    "Type",
    "NumberOfEmployees",
    "BillingCity",
    "ShippingCity",
    "AnnualRevenue",
  ];
}