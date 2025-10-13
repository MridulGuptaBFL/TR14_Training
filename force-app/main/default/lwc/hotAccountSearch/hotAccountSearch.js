import { LightningElement, track } from 'lwc';
import searchAccounts from '@salesforce/apex/HotAccountSearchController.searchAccounts';
import getAccountDetails from '@salesforce/apex/HotAccountSearchController.getAccountDetails';
 
export default class HotAccountSearch extends LightningElement {
    @track searchKey = '';
    @track accountOptions;
    @track selectedAccountId;
    @track accountInfo;
    @track selectedOpportunityName;
 
    handleInput(event) {
        this.searchKey = event.target.value;
    }
 
    async handleSearch() {
        try {
            const results = await searchAccounts({ accountName: this.searchKey });
            this.accountOptions = results.map(account => ({
                label: account.Name, value: account.Id
            }));
        } catch (error) {
            this.accountOptions = [];
            console.error(error);
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
            console.error(error);
        }
    }
 
    handleOpportunitySelect(event) {
        this.selectedOpportunityName = event.detail.name;
    }
}