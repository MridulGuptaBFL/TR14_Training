import { LightningElement, track } from "lwc";
import createOpp from "@salesforce/apex/OpportunityController.createOpp";
import { ShowToastEvent } from "lightning/platformShowToastEvent";
import OPP_SUCCESS from "@salesforce/label/c.Opp_Created_Success";
import OPP_ERROR from "@salesforce/label/c.Opp_Validation_Error";
export default class OpportunityList extends LightningElement {
  @track opportunities = [];
  @track oppName = "";
  @track oppAmount = "";
  @track oppStage = "Prospecting"; // default stage
  @track columns = [
    {
      label: "Opportunity Name",
      fieldName: "opportunityUrl",
      type: "url",
      typeAttributes: { label: { fieldName: "Name" }, target: "_blank" },
    },
    {
      label: "Account Name",
      fieldName: "accountUrl",
      type: "url",
      typeAttributes: { label: { fieldName: "AccountName" }, target: "_blank" },
    },
    { label: "Stage", fieldName: "StageName", type: "text" },
    { label: "Amount", fieldName: "Amount", type: "currency" },
  ];
  handleNameChange(event) {
    this.oppName = event.target.value;
  }
  handleAmountChange(event) {
    this.oppAmount = event.target.value;
  }
  handleStageChange(event) {
    this.oppStage = event.target.value;
  }
  async createOpportunity() {
    try {
      // Validation
      if (!this.oppName || !this.oppAmount || this.oppAmount <= 0) {
        this.showToast("Error", OPP_ERROR, "error");
        return;
      }
      const result = await createOpp({
        name: this.oppName,
        amount: parseFloat(this.oppAmount),
        stage: this.oppStage,
      });
      // Add to table

      this.opportunities = [
        ...this.opportunities,
        /* spread existing opportunities, 
        ... signifies spread operator; Spread operator allows an iterable such as an array or string to be expanded in places where 
        zero or more arguments (for function calls) or elements (for array literals) are expected, or an object expression to be expanded 
        in places where zero or more key-value pairs (for object literals) are expected.
        */
        {
          Id: result.Id,
          Name: result.Name,
          StageName: result.StageName,
          Amount: result.Amount,
          AccountName: result.Account.Name,
          opportunityUrl: `/lightning/r/Opportunity/${result.Id}/view`,
          accountUrl: `/lightning/r/Account/${result.AccountId}/view`,
        },
      ];
      // Success toast with link
      this.showToastWithLink(OPP_SUCCESS, result.Id);
      // Clear input fields
      this.oppName = "";
      this.oppAmount = "";
      this.oppStage = "Prospecting";
    } catch (error) {
      this.showToast("Error", error.body.message, "error");
    }
  }
  showToast(title, message, variant) {
    this.dispatchEvent(new ShowToastEvent({ title, message, variant }));
  }
  showToastWithLink(message, recordId) {
    this.dispatchEvent(
      new ShowToastEvent({
        title: "Success",
        message: message,
        messageData: [
          {
            url: `/lightning/r/Opportunity/${recordId}/view`,
            label: "View Opportunity",
          },
        ],
        variant: "success",
      })
    );
  }
}