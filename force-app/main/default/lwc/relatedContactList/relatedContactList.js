import { LightningElement, wire, track } from 'lwc';
import getContacts from '@salesforce/apex/PubsubAccountController.getContacts';
import { registerListener, unregisterAllListeners } from 'c/pubsub';
import { CurrentPageReference } from 'lightning/navigation';
 
export default class relatedContactList extends LightningElement {
    @track contacts;
    @track error;
    selectedAccountId;
    @wire(CurrentPageReference) pageRef;
 
    // Register listener when component loads
    connectedCallback() {
        registerListener('accountSelected', this.handleAccountSelected, this);
    }
 
    // Clean up listener when component is destroyed
    disconnectedCallback() {
        unregisterAllListeners(this);
    }
 
    // Fired when an account is selected in AccountList
    handleAccountSelected(accountId) {
        this.selectedAccountId = accountId;
 
        // Call Apex method with selected account Id
        getContacts({ accountId: this.selectedAccountId })
            .then(result => {
                this.contacts = result;
                this.error = undefined;
            })
            .catch(error => {
                this.contacts = undefined;
                this.error = error;
                console.error('Error fetching contacts:', error);
            });
    }
 
    // Columns for the datatable
    columns = [
        { label: 'First Name', fieldName: 'FirstName' },
        { label: 'Last Name', fieldName: 'LastName' },
        { label: 'Email', fieldName: 'Email' },
        { label: 'Mailing Address', fieldName: 'MailingStreet' }
    ];
 
    // Show "No Account selected" message when nothing selected
    get noAccountSelected() {
        return !this.selectedAccountId;
    }
}