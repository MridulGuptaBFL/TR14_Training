import { LightningElement, api, track, wire } from 'lwc';
import getContactsByAccountId from '@salesforce/apex/ContactController.getContactsByAccountId';
import createContactForAccount from '@salesforce/apex/ContactController.createContactForAccount';
import getAccountDetails from '@salesforce/apex/ContactController.getAccountDetails';
import updateAccount from '@salesforce/apex/ContactController.updateAccount';
import {updateRecord} from 'lightning/uiRecordApi';
import { refreshApex } from '@salesforce/apex';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';

export default class ContactList extends LightningElement {

  @api recordId;
  @track searchKey = "";
  @track contacts;
  wiredContactsResult;
  @track error;
  @track showCreateModal = false;
  @track showUpdateModal = false;

  @track newContact = {
    FirstName: "",
    LastName: "",
    Email: "",
    Phone: "",
    Title: "",
  };

  @track accountRecord = {
    Name: "",
    Phone: "",
    Website: "",
    Industry: "",
    Type: "",
  };

  columns = [
    { label: "Id", fieldName: "Id" },
    { label: "First Name", fieldName: "FirstName" },
    { label: "Last Name", fieldName: "LastName" },
    { label: "Email", fieldName: "Email", type: "email" },
    { label: "Phone", fieldName: "Phone", type: "phone" },
    { label: "Title", fieldName: "Title" },
  ];

  @wire(getContactsByAccountId, {
    accountId: "$recordId",
    searchKey: "$searchKey",
  })
  wiredContacts(result) {
    this.wiredContactsResult = result;

    const { data, error } = result;

    if (data) {
      this.contacts = data;

      this.error = undefined;
    } else if (error) {
      this.error = error;

      this.contacts = undefined;
    }
  }

  /* ---------- Search ---------- */

  handleSearchChange(event) {
    this.searchKey = event.target.value;
  }

  handleSearch() {
    // reactive property searchKey triggers wire automatically,
    // but call refreshApex to force immediate refresh if needed
    if (this.wiredContactsResult) {
      refreshApex(this.wiredContactsResult);
    }
  }

  /* ---------- Create Contact ---------- */

  handleCreateContact() {
    this.showCreateModal = true;
  }

  handleFieldChange(event) {
    const field = event.target.dataset.field;

    if (field) {
      this.newContact[field] = event.target.value;
    }
  }

  async createContact() {
    try {
      await createContactForAccount({
        accountId: this.recordId,
        contactData: this.newContact,
      });

      this.showToast("Success", "Contact created successfully", "success");

      this.closeModal();

      // reset form

      this.newContact = {
        FirstName: "",
        LastName: "",
        Email: "",
        Phone: "",
        Title: "",
      };

      // refresh datatable

      if (this.wiredContactsResult) await refreshApex(this.wiredContactsResult);
    } catch (err) {
      const msg =
        err && err.body && err.body.message
          ? err.body.message
          : "Error creating contact";

      this.showToast("Error", msg, "error");
    }
  }

  /* ---------- Update Account ---------- */

  handleUpdateAccount() {
    getAccountDetails({ accountId: this.recordId })
      .then((result) => {
        this.accountRecord = { ...result }; // shallow copy

        this.showUpdateModal = true;
      })

      .catch((err) => {
        const msg =
          err && err.body && err.body.message
            ? err.body.message
            : "Error fetching account details";

        this.showToast("Error", msg, "error");
      });
  }

  handleAccountChange(event) {
    const field = event.target.dataset.field;

    if (field) {
      this.accountRecord[field] = event.target.value;
    }
  }

  // async updateAccountRecord() {
  //   try {
  //     await updateAccount({ acc: this.accountRecord });

  //     this.showToast("Success", "Account updated successfully", "success");

  //     this.closeModal();
  //   } catch (err) {
  //     const msg =
  //       err && err.body && err.body.message
  //         ? err.body.message
  //         : "Error updating account";

  //     this.showToast("Error", msg, "error");
  //   }
  // }
  
        async updateAccountRecord(){
            try{
                const fields = {
                    Id: this.recordId,
                    ...this.accountRecord
                };
 
                const recordInput = {fields};
 
                await updateRecord(recordInput);
                this.showToast("Success", "Account updated successfully", "success");
                this.closeModal();
            }catch(err){
                const message = err && err.body && err.body.message ? err.body.message : "Error updating account";
                this.showToast("Error", message, "error");
            }
          }

  /* ---------- Helpers ---------- */

  closeModal() {
    this.showCreateModal = false;
    this.showUpdateModal = false;
  }

  showToast(title, message, variant) {
    this.dispatchEvent(new ShowToastEvent({ title, message, variant }));
  }
}