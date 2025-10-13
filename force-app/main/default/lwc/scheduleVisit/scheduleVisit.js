import { LightningElement, api } from "lwc";
import createTask from "@salesforce/apex/ScheduleVisitController.createTask";

export default class ScheduleVisit extends LightningElement {
  @api selectedProperty;
  @api contactName;
  visitDate;
  visitReason;

  handleDateChange(event) {
    this.visitDate = event.target.value;
  }

  handleReasonChange(event) {
    this.visitReason = event.target.value;
  }

  async handleSchedule() {
    try {
      await createTask({
        propertyId: this.selectedProperty,
        contactName: this.contactName,
        visitDate: this.visitDate,
        reason: this.visitReason,
      });

      // Notify Flow of success
      this.dispatchEvent(
        new CustomEvent("taskstatus", { detail: { success: true } })
      );
    } 
    
    catch (error) {
      // Notify Flow of failure
      this.dispatchEvent(
        new CustomEvent("taskstatus", { detail: { success: false } })
      );
    }
  }
}