import { LightningElement, api, wire, track } from 'lwc';
import getOpenOpportunities from '@salesforce/apex/HotAccountSearchController.getOpenOpportunities';

export default class HotAccountOpportunities extends LightningElement {
    @api accountId;
    @track opportunities;

    @wire(getOpenOpportunities, { accountId: '$accountId' })
    wiredOpps({ error, data }) {
        if (data) {
            this.opportunities = data;
        } else if (error) {
            this.opportunities = [];
            console.error('Error fetching opportunities:', error);
        }
    }

    fireSelect(event) {
        const { id, name } = event.target.dataset;
        this.dispatchEvent(new CustomEvent('oppselect', {
            detail: { id, name }
        }));
    }
}