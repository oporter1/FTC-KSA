import { LightningElement, api, wire } from 'lwc';
import { getRecord } from 'lightning/uiRecordApi';
import { NavigationMixin } from 'lightning/navigation';
import { CloseActionScreenEvent } from 'lightning/actions';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';

import getOtherInvoice from '@salesforce/apex/TransferPaymentController.getOtherInvoice';
import transferPayment from '@salesforce/apex/TransferPaymentController.transferPayment';

const columns = [
    { label: 'Invoice Number', fieldName: 'Name', sortable: true},
    { label: 'Balance', fieldName: 'fw1__Balance_Due__c', type: 'currency', sortable: true},
    { label: 'Due Date', fieldName: 'fw1__Due_Date__c', type: 'date', sortable: true}
];

const FIELDS = ['fw1__Invoice__c.fw1__Account__c',
                'fw1__Invoice__c.fw1__Contact__r.Name',
                'fw1__Invoice__c.fw1__Total_Paid_Amount__c',
                'fw1__Invoice__c.fw1__Email_Currency_Symbol__c',
                'fw1__Invoice__c.Name',
                'fw1__Invoice__c.fw1__Installment_Count__c'
            ];

export default class TransferPayment extends LightningElement {

    @api recordId;
    retrievedRecordId = false;

    columns = columns;
    invoiceList=[];
    initialRecords=[];
    transferToInvoice;
    paidAmount;
    amount;
    invoice;
    amountPlaceholder;

    sortedBy;
    defaultSortDirection = 'asc';
    sortDirection = 'asc';

    @wire(getRecord, {
        recordId: '$recordId',
        fields: FIELDS
    })
    wiredRecord({ error, data }) {
        if(data){
            this.invoice = data;
            this.paidAmount = data.fields.fw1__Total_Paid_Amount__c.value;
            this.amountPlaceholder = `Maximum allowable amount to transfer ${data.fields.fw1__Total_Paid_Amount__c.displayValue}`;

            getOtherInvoice({invoiceId: data.id,
                             accountId: data.fields.fw1__Account__c.value,
                             contactId: data.fields.fw1__Contact__r.value.id})
            .then(result => {
                this.invoiceList = result; // set all invoice in main list
                this.initialRecords = result; // set all invoice at first time
            })
            .catch(error => {
                console.log(error);
            })
        }
    }

    getSelected(event) {
        const selectedRows = event.detail.selectedRows;
        let tempTransferToInvoice = [];
        // Display that fieldName of the selected rows
        for (let i = 0; i < selectedRows.length; i++) {
            tempTransferToInvoice.push(selectedRows[i].Id);
        }
        this.transferToInvoice = tempTransferToInvoice;
    }

    handleAmountChange(event) {
        this.amount = event.detail.value;

        let amountCmp = this.template.querySelector(".inputamount");
        amountCmp.setCustomValidity(``);
        if(this.amount > this.paidAmount){
            amountCmp.setCustomValidity(`Amount to transfer must not be more than the paid amount.`);
        }
        amountCmp.reportValidity();
    }

    closeAction(){
        this.dispatchEvent(new CloseActionScreenEvent());
    }

    saveAction(){
        if(!this.amount
            || this.amount > this.paidAmount){
            let amountCmp = this.template.querySelector(".inputamount");
            amountCmp.reportValidity();
        }
        else if(this.transferToInvoice){
            const requestParam = {
                toInvoiceIds: this.transferToInvoice,
                amount: this.amount,
                acc: {
                    sobjectType: "Account",
                    Id: this.invoice.fields.fw1__Account__c.value
                },
                con: {
                    sobjectType: "Contact",
                    Id: this.invoice.fields.fw1__Contact__r.value.id,
                    Name: this.invoice.fields.fw1__Contact__r.value.fields.Name.value
                },
                inv: {
                    sobjectType: "fw1__Invoice__c",
                    Id: this.recordId,
                    Name: this.invoice.fields.Name.value,
                    fw1__Email_Currency_Symbol__c: this.invoice.fields.fw1__Email_Currency_Symbol__c.value,
                    fw1__Total_Paid_Amount__c: this.invoice.fields.fw1__Total_Paid_Amount__c.value,
                    fw1__Installment_Count__c: this.invoice.fields.fw1__Installment_Count__c.value
                }
            };

            transferPayment({req: requestParam})
            .then(result => {
                // alert here
                this.dispatchEvent(new ShowToastEvent({
                    title: 'Payment successfully transferred.',
                    message: '',
                    variant: 'success',
                }));

                // then close
                this.dispatchEvent(new CloseActionScreenEvent());

                setTimeout(() => { window.location.reload(); }, 2000);
            })
            .catch(error => {
                this.dispatchEvent(new ShowToastEvent({
                    title: 'Error',
                    message: JSON.stringify(error),
                    variant: 'error',
                }));
            })
        }
        else {
            this.dispatchEvent(new ShowToastEvent({
                title: 'Unable to transfer Payment. Please select invoice',
                message: '',
                variant: 'warning',
            }));
        }
    }

    // sort

    onHandleSort( event ) {

        const { fieldName: sortedBy, sortDirection } = event.detail;
        const cloneData = [...this.invoiceList];

        cloneData.sort( this.sortBy( sortedBy, sortDirection === 'asc' ? 1 : -1 ) );
        this.invoiceList = cloneData;
        this.sortDirection = sortDirection;
        this.sortedBy = sortedBy;

    }

    sortBy( field, reverse, primer ) {

        const key = primer
            ? function( x ) {
                  return primer(x[field]);
              }
            : function( x ) {
                  return x[field];
              };

        return function( a, b ) {
            a = key(a);
            b = key(b);
            return reverse * ( ( a > b ) - ( b > a ) );
        };
    }

    // search
    handleSearchChange( event ) {
        this.searchString = event.detail.value;
    }

    handleSearch( event ) {
        const searchKey = event.target.value.toLowerCase();
        if ( searchKey ) {
            this.invoiceList = this.initialRecords;

            if ( this.invoiceList ) {
                let recs = [];
                for ( let rec of this.invoiceList ) {
                    let valuesArray = Object.values( rec );

                    for ( let val of valuesArray ) {

                        let strVal = String( val );

                        if ( strVal ) {
                            if ( strVal.toLowerCase().includes( searchKey ) ) {
                                recs.push( rec );
                                break;
                            }
                        }
                    }
                }
                this.invoiceList = recs;
             }
        }  else {
            this.invoiceList = this.initialRecords;
        }
    }
}