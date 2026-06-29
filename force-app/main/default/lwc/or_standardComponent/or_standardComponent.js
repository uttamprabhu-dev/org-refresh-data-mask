import { LightningElement } from 'lwc';
import maskStandardData from '@salesforce/apex/PostRefreshOrgProcessController.maskStandardData';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';

export default class Or_standardComponent extends LightningElement {
    async handleMaskData() {
        try {
            const result = await maskStandardData();
            if (result.success) {
                this.dispatchEvent(new ShowToastEvent({
                    title: "Batch class scheduled",
                    message: "Open the 'Setup -> Apex' Jobs for checking their status.",
                }));
            }
        } catch (error) {
            console.log('result', error.message);
        }
    }
}