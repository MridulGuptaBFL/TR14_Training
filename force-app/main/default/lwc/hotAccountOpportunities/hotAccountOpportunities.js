import { LightningElement, api, wire, track } from 'lwc';
import { refreshApex } from '@salesforce/apex';
import getOpenOpportunities from '@salesforce/apex/HotAccountSearchController.getOpenOpportunities';
import createOpp from '@salesforce/apex/OpportunityController.createOpp';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import OPP_SUCCESS from '@salesforce/label/c.Opp_Created_Success';
import OPP_ERROR from '@salesforce/label/c.Opp_Validation_Error';

export default class HotAccountOpportunities extends LightningElement {
    @api accountId;
    @track opportunities = [];
    wiredOppsResult; // store wired result for refreshApex

    // fields for create form
    @track oppName = '';
    @track oppAmount = '';
    @track oppStage = 'Prospecting';

    // datatable columns
    @track columns = [
        {
            label: 'Opportunity Name',
            fieldName: 'opportunityUrl',
            type: 'url',
            typeAttributes: { label: { fieldName: 'Name' }, target: '_blank' }
        },
        {
            label: 'Account Name',
            fieldName: 'accountUrl',
            type: 'url',
            typeAttributes: { label: { fieldName: 'AccountName' }, target: '_blank' }
        },
        { label: 'Stage', fieldName: 'StageName', type: 'text' },
        { label: 'Amount', fieldName: 'Amount', type: 'currency' },
        { label: 'Owner Email', fieldName: 'OwnerEmail', type: 'text' },
        {
            type: 'button',
            fixedWidth: 120,
            typeAttributes: {
                label: 'Select',
                name: 'select',
                title: 'Select Opportunity'
            }
        }
    ];

    @wire(getOpenOpportunities, { accountId: '$accountId' })
    wiredOpps(result) {
        this.wiredOppsResult = result;
        const { error, data } = result;
        if (data) {
            // Normalize data for datatable (add urls and flattened fields)
            this.opportunities = data.map(opp => {
                return {
                    Id: opp.Id,
                    Name: opp.Name || '',
                    StageName: opp.StageName || '',
                    // ensure Amount is a number (datatable currency requires numeric)
                    Amount: opp.Amount != null ? Number(opp.Amount) : null,
                    // flattened account/owner fields used by columns
                    AccountName: opp.Account ? opp.Account.Name : '',
                    OwnerEmail: opp.Owner ? opp.Owner.Email : '',
                    // url fields used by url columns
                    opportunityUrl: `/lightning/r/Opportunity/${opp.Id}/view`,
                    accountUrl: opp.AccountId ? `/lightning/r/Account/${opp.AccountId}/view` : null
                };
            });
        } else if (error) {
            this.opportunities = [];
            // eslint-disable-next-line no-console
            console.error('Error fetching opportunities:', error);
        } else {
            this.opportunities = [];
        }
    }

    handleNameChange(event) {
        this.oppName = event.target.value;
    }

    handleAmountChange(event) {
        this.oppAmount = event.target.value;
    }

    handleStageChange(event) {
        this.oppStage = event.target.value;
    }

    async createOpportunity() {
        try {
            // Validation
            if (!this.oppName || !this.oppAmount || this.oppAmount <= 0) {
                this.showToast('Error', OPP_ERROR, 'error');
                return;
            }

            const params = {
                name: this.oppName,
                amount: parseFloat(this.oppAmount),
                stage: this.oppStage
                // NOTE: removed accountId to match the original Apex signature
            };

            const result = await createOpp(params);

            // Refresh the wired list so datatable reflects server state
            if (this.wiredOppsResult) {
                try {
                    await refreshApex(this.wiredOppsResult);
                    // eslint-disable-next-line no-console
                    console.log('Opportunities refreshed after create');
                } catch (refreshErr) {
                    // eslint-disable-next-line no-console
                    console.error('refreshApex error:', refreshErr);
                }
            } else {
                // eslint-disable-next-line no-console
                console.warn('No wiredOppsResult available to refresh');
            }

            // Show success with link
            this.showToastWithLink(OPP_SUCCESS, result.Id);

            // Clear inputs
            this.oppName = '';
            this.oppAmount = '';
            this.oppStage = 'Prospecting';
        } catch (error) {
            // better error extraction and logging
            const msg = (error && error.body && error.body.message) ? error.body.message : (error.message || JSON.stringify(error));
            // eslint-disable-next-line no-console
            console.error('createOpportunity error:', error);
            this.showToast('Error', msg, 'error');
        }
    }

    // handle datatable button clicks
    handleRowAction(event) {
        const actionName = event.detail.action.name;
        const row = event.detail.row;
        if (actionName === 'select') {
            this.dispatchEvent(new CustomEvent('oppselect', {
                detail: { id: row.Id, name: row.Name },
                bubbles: true,
                composed: true
            }));
        }
    }

    // kept for compatibility with any existing button-based rows (not used when datatable is present)
    fireSelect(event) {
        const dataset = event.currentTarget?.dataset || {};
        const id = dataset.id;
        const name = dataset.name;
        this.dispatchEvent(new CustomEvent('oppselect', {
            detail: { id, name },
            bubbles: true,
            composed: true
        }));
    }

    showToast(title, message, variant) {
        this.dispatchEvent(new ShowToastEvent({ title, message, variant }));
    }

    showToastWithLink(message, recordId) {
        this.dispatchEvent(
            new ShowToastEvent({
                title: 'Success',
                message: message,
                messageData: [
                    {
                        url: `/lightning/r/Opportunity/${recordId}/view`,
                        label: 'View Opportunity'
                    }
                ],
                variant: 'success'
            })
        );
    }
}