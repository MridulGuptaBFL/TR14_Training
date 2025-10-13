import { LightningElement, api } from "lwc";
import { ShowToastEvent } from "lightning/platformShowToastEvent";
export default class AccountEditForm extends LightningElement {
  @api recordId;
  handleSubmit(event) {
    // Perform client-side validation if needed
    const fields = event.detail.fields;
    if (!fields.Phone || !fields.Website) {
      event.preventDefault(); // Prevent save
      this.showToast("Error", "Phone and Website are required", "error");
    }
  }
  handleSuccess(event) {
    this.showToast("Success", "Account updated successfully", "success");
  }
  handleError(event) {
    const message = event.detail.message || "Error updating Account";
    this.showToast("Error", message, "error");
  }
  showToast(title, message, variant) {
    this.dispatchEvent(new ShowToastEvent({ title, message, variant }));
  }
}