import { LightningElement, track, wire } from 'lwc';
import getAllSObjects from '@salesforce/apex/QueryBuilderController.getAllSObjects';
import getFields from '@salesforce/apex/QueryBuilderController.getFields'; 
import executeSoql from '@salesforce/apex/QueryBuilderController.executeSoql'; 
import { ShowToastEvent } from 'lightning/platformShowToastEvent'; 
import { NavigationMixin } from 'lightning/navigation'; 

export default class QueryBuilder extends NavigationMixin(LightningElement) { 
  
    // ======================= 
    // Reactive variables
    // ======================= 
    @track allObjectOptions = []; // Stores the full list of objects 
    @track filteredObjectOptions = []; // Filtered list for the search dropdown 
    @track objectSearchTerm = ''; 
    @track showObjectDropdown = false; 
    @track fieldOptions = []; 
    @track selectedObject = ''; 
    @track selectedFields = []; 
    @track limitValue = '500'; 
    @track query = ''; 
    @track records = []; 
    @track columns = []; 
    @track error; 
    sortedBy; 
    sortedDirection = 'asc'; 


    // ======================= 
    // Max record options 
    // ======================= 
    limitOptions = [ 
        { label: '500', value: '500' }, 
        { label: '1000', value: '1000' }, 
        { label: '5000', value: '5000' }, 
        { label: '50000', value: '50000' }, 
    ]; 

  
    // ======================= 
    // Fetch all available objects from Apex 
    // ======================= 
    @wire(getAllSObjects) 
    wiredObjects({ data, error }) { 
        if (data) { 
            this.allObjectOptions = data.map(obj => ({ label: obj, value: obj })); 
            this.filteredObjectOptions = [...this.allObjectOptions]; 
        } else if (error) { 
            this.showToast('Error', error.body ? error.body.message : error.message, 'error'); 
        } 
    } 
    

    // ======================= 
    // Handle object search input 
    // ======================= 
    handleObjectSearch(event) { 
        this.objectSearchTerm = event.target.value; 
        const searchTermLower = this.objectSearchTerm.toLowerCase(); 

        
        if (searchTermLower) { 
            this.filteredObjectOptions = this.allObjectOptions.filter( 
                obj => obj.label.toLowerCase().includes(searchTermLower) 
            ); 
        } else { 
            this.filteredObjectOptions = [...this.allObjectOptions]; 
        } 
    } 

    
    // ======================= 
    // Show object dropdown on focus 
    // ======================= 
    handleObjectInputFocus() { 
        this.showObjectDropdown = true; 
    } 

    
    // ======================= 
    // Hide object dropdown on blur (with delay) 
    // ======================= 
    handleObjectInputBlur() { 
        // Use a slight delay to allow the click on the dropdown to register 
        setTimeout(() => { 
            this.showObjectDropdown = false; 
        }, 200); 
    } 

    
    // ======================= 
    // Handle object selection from dropdown 
    // ======================= 
    handleObjectClick(event) { 
        this.selectedObject = event.currentTarget.dataset.value; 
        this.objectSearchTerm = this.selectedObject; 
        this.showObjectDropdown = false; 

        
        this.selectedFields = []; 
        this.fieldOptions = []; 
        this.query = ''; 
        this.records = []; 
        this.columns = []; 
        this.error = undefined; 
  
        getFields({ objectName: this.selectedObject }) 
            .then(result => { 
                this.fieldOptions = result.map(f => ({ label: f, value: f })); 
            }) 
            .catch(error => { 
                this.showToast('Error', error.body ? error.body.message : error.message, 'error'); 
            }); 
    } 


    // ======================= 
    // Handle field selection change 
    // ======================= 
    handleFieldChange(event) { 
        this.selectedFields = event.detail.value; 
        this.generateQuery(); 
    } 

  
    // ======================= 
    // Handle max record change 
    // ======================= 
    handleLimitChange(event) { 
        this.limitValue = event.detail.value; 
        this.generateQuery(); 
    } 

  
    // ======================= 
    // Handle manual query input 
    // ======================= 
    handleQueryChange(event) { 
        this.query = event.detail.value; 
    } 
  

    // ======================= 
    // Generate dynamic SOQL 
    // ======================= 
    generateQuery() { 
        if (this.selectedObject && this.selectedFields.length > 0) { 
            // Ensure Id and Name are always part of the query for record links 
            const fieldsToQuery = [...new Set(['Id', 'Name', ...this.selectedFields])].filter(f => f); 
            this.query = `SELECT ${fieldsToQuery.join(', ')} FROM ${this.selectedObject} LIMIT ${this.limitValue}`; 
        } 
    }
  
    // ======================= 
    // Execute SOQL query 
    // ======================= 
    executeQuery() { 
        if (!this.query) { 
            this.showToast('Error', 'Please build or enter a query before executing.', 'error'); 
            return; 
        } 
        
        this.records = []; 
        this.columns = []; 
        this.error = undefined; 
  
        executeSoql({ soql: this.query }) 
            .then(result => { 
                if (result && result.rows && result.rows.length > 0) { 
                    this.records = this.addLinksToRecords(result.rows); 
                    this.columns = this.generateTableColumns(result.columns); 
                    this.showToast('Success', 'Query executed successfully!', 'success'); 
                } else { 
                    this.showToast('Info', 'No records found.', 'info'); 
                } 
            }) 
            .catch(error => { 
                this.records = []; 
                this.columns = []; 
                this.error = error.body ? error.body.message : error.message; 
                this.showToast('Query Failed', this.error, 'error'); 
            }); 
    } 

  
    // ======================= 
    // Add record links to result data 
    // ======================= 
    addLinksToRecords(rows) { 
        return rows.map(row => { 
            const newRow = { ...row }; 
            if (newRow.Name && newRow.Id) { 
                newRow.recordLink = `/${newRow.Id}`; 
            } 
            return newRow; 
        }); 
    } 

  
    // ======================= 
    // Generate columns for datatable 
    // ======================= 
    generateTableColumns(fieldNames) { 
        return fieldNames.map(fieldName => { 
            if (fieldName === 'Name' && this.selectedFields.includes('Name')) { 
                return { 
                    label: 'Name', 
                    fieldName: 'recordLink', 
                    type: 'url', 
                    typeAttributes: { 
                        label: { fieldName: 'Name' }, 
                        target: '_blank' 
                    }, 
                    sortable: true 
                }; 
            } 
            return { 
                label: fieldName, 
                fieldName: fieldName, 
                sortable: true 
            }; 
        }); 
    } 

  
    // ======================= 
    // Clear all selections 
    // ======================= 
    clearAll() { 
        this.selectedObject = ''; 
        this.selectedFields = []; 
        this.objectSearchTerm = ''; 
        this.filteredObjectOptions = [...this.allObjectOptions]; 
        this.fieldOptions = []; 
        this.query = ''; 
        this.records = []; 
        this.columns = []; 
        this.error = undefined; 
    } 

  
    // ======================= 
    // Handle datatable sorting 
    // ======================= 
    handleSort(event) { 
        const { fieldName: sortedBy, sortDirection } = event.detail; 
        const cloneData = [...this.records]; 
        cloneData.sort((a, b) => { 
            let aValue = a[sortedBy]; 
            let bValue = b[sortedBy]; 
            if (aValue === undefined || aValue === null) aValue = ''; 
            if (bValue === undefined || bValue === null) bValue = ''; 
            const isReverse = sortDirection === 'asc' ? 1 : -1; 
            return isReverse * ((aValue > bValue) - (aValue < bValue)); 
        }); 
        this.records = cloneData; 
        this.sortedBy = sortedBy; 
        this.sortedDirection = sortDirection; 
    } 

    // ======================= 
    // Show toast notifications 
    // ======================= 
    showToast(title, message, variant) { 
        this.dispatchEvent(new ShowToastEvent({ title, message, variant })); 
    } 
}