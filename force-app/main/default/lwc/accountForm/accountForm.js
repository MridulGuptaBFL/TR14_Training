import { LightningElement, api, track } from "lwc";
export default class AccountForm extends LightningElement {
  @api recordId;
  // Fields to display in the form
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