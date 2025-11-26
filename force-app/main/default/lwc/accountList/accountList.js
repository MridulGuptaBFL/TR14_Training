import { LightningElement, wire } from 'lwc';
import getAccounts from '@salesforce/apex/PubsubAccountController.getAccounts';
import { fireEvent } from 'c/pubsub';
import { CurrentPageReference } from 'lightning/navigation';
 
export default class accountList extends LightningElement {
    // To store which Account is selected
    selectedAccountId;
 
    // Get current page reference (required by pubsub)
    @wire(CurrentPageReference) pageRef;
 
    // Fetch all Accounts using the Apex method
    @wire(getAccounts)
    accounts;
 
    // Convert Accounts into combobox options (Label → Account Name, Value → Id)
    get accountOptions() {
        return this.accounts.data
            ? this.accounts.data.map(acc => ({ label: acc.Name, value: acc.Id }))
            : [];
    }
 
    // Called when user selects an Account from dropdown
    handleAccountChange(event) {
        this.selectedAccountId = event.detail.value; // store selected Id
        // Publish (fire) the selected Account Id event using PubSub
    fireEvent(this.pageRef, 'accountSelected', this.selectedAccountId);
    }
}