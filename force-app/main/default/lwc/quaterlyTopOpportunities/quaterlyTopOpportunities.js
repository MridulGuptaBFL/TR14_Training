import { LightningElement, track } from 'lwc';
import getTopQuarterlyOpportunities from '@salesforce/apex/TopQuarterlyOpportunitiesController.getTopQuarterlyOpportunities';
 
export default class QuarterlyTopOpportunities extends LightningElement {
    @track opportunities = [];
    @track noData = false;
 
    handleClick() {
        getTopQuarterlyOpportunities()
            .then(result => {
                this.opportunities = result;
                this.noData = result.length === 0;
            })
            .catch(error => {
                this.opportunities = [];
                this.noData = true;
            });
    }
}