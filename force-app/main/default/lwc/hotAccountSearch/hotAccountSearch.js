import { LightningElement, track } from 'lwc';
import searchAccounts from '@salesforce/apex/HotAccountSearchController.searchAccounts';
import getAccountDetails from '@salesforce/apex/HotAccountSearchController.getAccountDetails';
 
export default class HotAccountSearch extends LightningElement {
    @track searchKey = '';
    @track accountOptions = [];
    @track selectedAccountId = '';
    @track accountInfo = null;
    @track selectedOpportunityName = null;
 
    handleInput(event) {
        // use event.detail.value for lightning-input
        this.searchKey = event.detail.value;
    }
 
    async handleSearch() {
        try {
            const results = await searchAccounts({ accountName: this.searchKey });
            // ensure results is an array before mapping
            this.accountOptions = (results || []).map(account => ({
                label: account.Name, value: account.Id
            }));
        } catch (error) {
            this.accountOptions = [];
            console.error('Apex searchAccounts error:', error);
        }
    }

    async handleSelect(event) {
        try {
            this.selectedAccountId = event.detail.value;
            const info = await getAccountDetails({ accountId: this.selectedAccountId });
            this.accountInfo = info;
            this.selectedOpportunityName = null;
        } catch (error) {
            this.accountInfo = null;
            console.error('Apex getAccountDetails error:', error);
        }
    }
 
    handleOpportunitySelect(event) {
        this.selectedOpportunityName = event.detail.name;
    }
}