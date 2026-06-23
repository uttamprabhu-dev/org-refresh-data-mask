import { LightningElement, wire } from 'lwc';
import { getRecord, getFieldValue } from 'lightning/uiRecordApi';
import userId from '@salesforce/user/Id';
import PROFILE_NAME_FIELD from '@salesforce/schema/User.Profile.Name';

export default class PostRefreshOrgProcess extends LightningElement {
    isAdmin = false;
    isLoading = true;

    @wire(getRecord, { recordId: userId, fields: [PROFILE_NAME_FIELD] })
    wiredUser({ error, data }) {
        if (data) {
            this.isAdmin = getFieldValue(data, PROFILE_NAME_FIELD) === 'System Administrator';
            this.isLoading = false;
        } else if (error) {
            this.isAdmin = false;
            this.isLoading = false;
        }
    }

    get showAccessDeniedModal() {
        return !this.isLoading && !this.isAdmin;
    }
}
