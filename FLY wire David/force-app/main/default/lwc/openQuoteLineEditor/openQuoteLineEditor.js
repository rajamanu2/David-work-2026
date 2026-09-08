import { LightningElement, api} from 'lwc';
import { NavigationMixin } from 'lightning/navigation';


export default class OpenQuoteLineEditor extends NavigationMixin (LightningElement) {
    @api quoteId;
    sfdcBaseURL;

    connectedCallback() {
        // get base URl from Salesforce and append quoteId from Flow
        this.sfdcBaseURL = window.location.origin + '/apex/sbqq__sb?id=' + this.quoteId;
        this.navigateToVFPage(); 
    }

    navigateToVFPage() {
        // Navigate to Quote Line Editor URL
        this[NavigationMixin.GenerateUrl]({
            type: 'standard__webPage',
            attributes: {
                url: this.sfdcBaseURL
            }
        }).then(vfURL => {
            if(vfURL != null){
                window.open(vfURL, "_self");
            }else{
                throw new error();
            }
        }).catch(error => {
            alert("Invalid URL - please contact Salesforce Admin");
            console.error("error in openQuoteLineEditor LWC: ", error);
        });
    }
}