import { LightningElement } from 'lwc';
import maskContactData from '@salesforce/apex/PostRefreshOrgProcessController.maskContactData'
import { ShowToastEvent } from "lightning/platformShowToastEvent";

export default class PostRefreshOrgProcess extends LightningElement {
    async handleMaskData() {
        try {
            const result = await maskContactData();
            if(result.success) {
                this.dispatchEvent(new ShowToastEvent({
                    title: "Get Help",
                    message:
                        "Salesforce documentation is available in the app. Click ? in the upper-right corner.",
                }));
            }
        } catch (error) {
            console.log('result', error.message);
        }
    }
}