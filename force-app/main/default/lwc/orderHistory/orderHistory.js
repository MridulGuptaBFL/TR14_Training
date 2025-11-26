import { LightningElement, track, api, wire } from 'lwc';
import getCustomerAccounts from '@salesforce/apex/OrderHistoryController.getCustomerAccounts';
import fetchOrders from '@salesforce/apex/OrderHistoryController.fetchOrders';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import { refreshApex } from '@salesforce/apex';

const DEFAULT_PAGE_SIZE = 5;

/**
 * @description LWC component to display and filter order history
 * @features
 * - Account filtering for customer users
 * - Period filtering
 * - Status filtering 
 * - Search functionality
 * - Pagination
 */
export default class OrderHistory extends LightningElement { 
    @track accountOptions = []; 
    @track orders = []; 
    @track isLoading = false; 
    @track noRecords = false;
    
    @api accountId;
 
    @track selectedPeriod = ''; 
    @track selectedStatus = ''; 
    @track selectedAccount = ''; 
    @track searchTerm = ''; 
 
    @track pageNumber = 1; 
    pageSize = DEFAULT_PAGE_SIZE; 
    @track totalSize = 0; 

    wiredOrdersResult;
 
    // picklist options 
    periodOptions = [ 
        { label: '-- All --', value: '' },
        { label: 'Last 3 Months', value: '3' }, 
        { label: 'Last 6 Months', value: '6' }, 
        { label: 'Last 9 Months', value: '9' }, 
        { label: 'Last 12 Months', value: '12' } 
    ]; 
    statusOptions = [
        { label: '-- All --', value: '' },
        { label: 'Draft', value: 'Draft' },
        { label: 'Activated', value: 'Activated' },
        { label: 'Created', value: 'Created' },
        { label: 'Shipped', value: 'Shipped' }
    ];

    connectedCallback(){ 
        this.loadAccounts(); 
    } 
 
    async loadAccounts(){ 
        try { 
            // fetch all accounts and mark which ones are customer-users in the label
            const allAccts = await getCustomerAccounts();
            this.accountOptions = [
                { label: '-- All --', value: '' },
                ...allAccts.map(a => ({
                    label: a.Name + (a.isCustomerUser__c ? ' (Customer)' : ''),
                    value: a.Id
                }))
            ];
        } catch (error) { 
            this.accountOptions = [{ label: '-- All --', value: '' }]; 
            this.dispatchEvent(
                new ShowToastEvent({
                    title: 'Error loading accounts',
                    message: error.body?.message || 'Unknown error',
                    variant: 'error'
                })
            );
        } 
    } 

    @wire(fetchOrders, { 
        accountIdStr: '$selectedAccount', 
        periodMonthsStr: '$selectedPeriod', 
        status: '$selectedStatus', 
        searchTerm: '$searchTerm', 
        pageNumberStr: '$pageNumber', 
        pageSizeStr: '$pageSize'
    })
    wiredFetch(result) {
        this.wiredOrdersResult = result;
        this.isLoading = true;
        this.noRecords = false;
        
        if(result.data) {
            try {
                this.totalSize = result.data.totalSize ? parseInt(result.data.totalSize, 10) : 0; 
                const records = result.data.records || [];
                this.orders = records.map(r => ({ 
                    ...r, 
                    orderDate: r.orderDate ? new Date(r.orderDate).toLocaleDateString() : '' 
                })); 
                this.noRecords = (this.orders.length === 0);
            } catch (e) {
                this.orders = [];
                this.noRecords = true;
                this.dispatchEvent(
                    new ShowToastEvent({
                        title: 'Error processing orders',
                        message: e.message,
                        variant: 'error'
                    })
                );
            } finally {
                this.isLoading = false;
            }
        } else if(result.error) {
            this.orders = [];
            this.noRecords = true;
            this.isLoading = false;
            this.dispatchEvent( 
                new ShowToastEvent({ 
                    title: 'Error loading orders', 
                    message: result.error.body?.message || 'Unknown error occurred', 
                    variant: 'error' 
                })
            );
        }
    }

    handlePeriodChange(event){ 
        this.selectedPeriod = event.detail.value || ''; 
        this.pageNumber = 1;
    } 

    handleStatusChange(event){ 
        this.selectedStatus = event.detail.value || ''; 
        this.pageNumber = 1;
    } 

    handleAccountChange(event){ 
        this.selectedAccount = event.detail.value || ''; 
        this.pageNumber = 1;
    } 

    handleSearchChange(event){ 
        this.searchTerm = event.target.value || ''; 
        this.pageNumber = 1;
        // refreshApex will automatically trigger when searchTerm changes
        refreshApex(this.wiredOrdersResult);
    }

    clearSearch(){
        this.searchTerm = '';
        this.pageNumber = 1;
        const input = this.template.querySelector('lightning-input[data-id="searchInput"]');
        if(input){
            input.value = '';
        }
        // Refresh after clearing
        refreshApex(this.wiredOrdersResult);
    }

    previousPage(){ 
        if (this.pageNumber > 1){ 
            this.pageNumber -= 1; 
        } 
    } 

    nextPage(){ 
        if ((this.pageNumber * this.pageSize) < this.totalSize){ 
            this.pageNumber += 1; 
        } 
    } 

    get prevDisabled(){ 
        return this.pageNumber <= 1; 
    } 

    get nextDisabled(){ 
        return (this.pageNumber * this.pageSize) >= this.totalSize; 
    } 
}