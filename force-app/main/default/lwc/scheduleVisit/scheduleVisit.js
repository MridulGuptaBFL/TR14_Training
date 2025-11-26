import { LightningElement, api, track } from 'lwc';
import createTask from '@salesforce/apex/ScheduleVisitController.createTask';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import { FlowNavigationNextEvent } from 'lightning/flowSupport';

export default class ScheduleVisit extends LightningElement {
    @api selectedProperty;
    @api contactName;

    @api availableActions = [];

    isNextAction() {
        console.log("Test actions --->" + this.availableActions.includes('NEXT'));
        return this.availableActions.includes('NEXT');
    }

    navigateNextFlowScreen() {
        console.log("Inside Next Flow Screen ---> ", this.availableActions);
        if (this.isNextAction) {
            console.log("Test next actions" + this.isNextAction);
        const navigateNext = new FlowNavigationNextEvent();
        this.dispatchEvent(navigateNext);
        }
    }

    @track visitDate;
    @track reason;

    handleDateChange(event){
        this.visitDate = event.target.value;
    }

    handleReasonChange(event){
        this.reason = event.target.value;
    }

    handleScheduleVisit(){
        if(!this.visitDate || !this.reason){
            this.dispatchEvent(
                new ShowToastEvent({
                    title: 'Error',
                    message: 'Please enter date and reason for visit',
                    variant: 'error'
                })
            );
            return;
        }

        createTask({ propertyId: this.selectedProperty, contactName: this.contactName, visitDate: this.visitDate, reason: this.reason })
        .then(result => {
            console.log('Inside Button Click!!');
            // Notify Flow about success
            const evt = new CustomEvent('taskstatus', { detail: { success: true } });
            this.dispatchEvent(evt);
            this.dispatchEvent(
                new ShowToastEvent({
                    title: 'Success',
                    message: 'Site visit has been successfully scheduled!',
                    variant: 'success'
                })
            );
            this.navigateNextFlowScreen(); //navigate to next flow screen
        })
        .catch(error => {
            console.log("propertyid:    --->"+this.selectedProperty);
            const evt = new CustomEvent('taskstatus', { detail: { success: false } });
            this.dispatchEvent(evt);
            let errorMessage = 'Error scheduling site visit';
            if (error.body && error.body.message) {
                errorMessage = error.body.message;
            }
            this.dispatchEvent(
                new ShowToastEvent({
                    title: 'Error',
                    message: errorMessage,
                    variant: 'error'
                })
            );
        });
    }
}




/*
flow next button configuration through lwc button: 
https://www.forcetrails.com/2024/08/control-screen-flow-navigation-from-lwc.html 
*/