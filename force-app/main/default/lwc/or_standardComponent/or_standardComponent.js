import { LightningElement } from 'lwc';
import maskStandardData from '@salesforce/apex/PostRefreshOrgProcessController.maskStandardData';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';

export default class Or_standardComponent extends LightningElement {
    async handleMaskData() {
        try {
            const result = await maskStandardData();
            if (result.success) {
                this.dispatchEvent(new ShowToastEvent({
                    title: "Get Help",
                    message: "Salesforce documentation is available in the app. Click ? in the upper-right corner.",
                }));
            }
        } catch (error) {
            console.log('result', error.message);
        }
    }
}