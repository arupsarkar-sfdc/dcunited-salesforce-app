import { LightningElement, api, track } from 'lwc';
//import the apex class ZeroCopyContactTransactionsController.getContactTransactions
import getContactTransactions from '@salesforce/apex/ZeroCopyContactTransactionsController.getContactTransactions';
import Amount from '@salesforce/schema/Opportunity.Amount';


//define columns
const columns = [
    //format the Transaction Id to show only the integer value, with scale 0




    { label: 'TransactionID', fieldName: 'TransactionID', type: 'number', typeAttributes: { minimumFractionDigits: 0, maximumFractionDigits: 0}},    
    { label: 'Transaction Date', fieldName: 'TransactionDate' },
    { label: 'Created Date', fieldName: 'CreatedDate'},
    { label: 'Amount', fieldName: 'Amount', type: 'currency' },
    { label: 'Description', fieldName: 'Description'},
    { label: 'Status', fieldName: 'Status'},
    { label: 'Transaction Type', fieldName: 'TransactionType'}
];

export default class ZeroCopyContactController extends LightningElement {
    @api recordId;
    //declare a result to hold the apex class method getContactTransactions return value
    @track result = [];
    @track transactions = [];
    //initialize columns
    columns = columns;
    //create a boolean for apex call start and end
    isLoading = false;
    dataValues;
    searchKey = '';

    connectedCallback() {
        console.log('recordId: ' + this.recordId);
        // this.isLoading = true;
        // //call the apex class method
        // getContactTransactions({ recordId: this.searchKey })
        //     .then(result => {
        //         this.result = JSON.parse(result);
        //         this.transactions = this.result.data.map(row => ({
        //             Amount: row[0],
        //             ContactID: row[1],
        //             CreatedBy: row[2],
        //             CreatedDate: row[3],
        //             Description: row[4],
        //             Email: row[5],
        //             Status: row[6],
        //             TransactionDate: row[7],
        //             TransactionID: row[8],
        //             TransactionType: row[9]

        //     }));
                // this.transactions = this.result.data;
                // this.dataValues = JSON.stringify(this.result);
                // console.log('result: ' + JSON.stringify(result));
                // console.log('data: ' + JSON.stringify(this.transactions));
            // })
            // .catch(error => {
            //     console.error('error: ' + error);
            // })
            // .finally(() => {
            //     console.log('finally');
            //     this.isLoading = false;
            // }
        // );
    }

    handleSearchChange(event) {
        const searchKey = event.target.value;
        this.searchKey = searchKey;
    }
    searchTransactions() {
        this.isLoading = true;
        getContactTransactions({ recordId: this.searchKey })
            .then(result => {
                this.result = JSON.parse(result);
                this.transactions = this.result.data.map(row => ({
                    Amount: row[0],
                    ContactID: row[1],
                    CreatedBy: row[2],
                    CreatedDate: row[3],
                    Description: row[4],
                    Email: row[5],
                    Status: row[6],
                    TransactionDate: row[7],
                    TransactionID: row[8],
                    TransactionType: row[9]
                }));
            })
            .catch(error => {
                console.error('error: ' + error);
            })
            .finally(() => {
                console.log('finally');
                this.isLoading = false;
            }
        );
    
    }

    loadData(data) {
        //iterate the data and push the data into the transactions array
        transactions = data.map(row => {
            return {
                TransactionDate: row.TransactionDate,
                ContactID: row.ContactID,
                CreatedDate: row.CreatedDate,
                Amount: row.Amount,
                Description: row.Description,
                TransactionID: row.TransactionID,
                Status: row.Status
            };
        });
            

    }
}