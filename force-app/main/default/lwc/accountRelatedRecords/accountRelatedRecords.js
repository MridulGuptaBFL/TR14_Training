import { LightningElement, api, wire } from 'lwc';
import getRelatedRecords from '@salesforce/apex/AccountRelatedDataController.getRelatedRecords';
 
export default class AccountRelatedRecords extends LightningElement {
    @api recordId; //@api makes recordId public and reactive
    contacts = [];
    opportunities = [];
    projects = [];
 
    @wire(getRelatedRecords, { accountId: '$recordId' }) //@wire to call Apex method
    wiredRecords({ error, data }) {
        if (data) {
            this.contacts = data.Contacts || [];
            this.opportunities = data.Opportunities || [];
            this.projects = data.Projects || [];
        } else if (error) {
            console.error('Error fetching related records:', error);
        }
    }
}