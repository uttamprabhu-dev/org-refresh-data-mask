import { LightningElement, track } from 'lwc';
import maskStandardData from '@salesforce/apex/PostRefreshOrgProcessController.maskStandardData'
import maskCustomData from '@salesforce/apex/PostRefreshOrgProcessController.maskCustomData'
import { ShowToastEvent } from "lightning/platformShowToastEvent";
import getNonSetupObjects from '@salesforce/apex/ObjectDataHelper.getNonSetupObjects';
import getObjectFields from '@salesforce/apex/ObjectDataHelper.getObjectFields';
export default class PostRefreshOrgProcess extends LightningElement {
    @track objectOptions = [];
    @track fieldOptions = [];
    @track tilesList = [];
    @track nextTileId = 1;
    @track selectedObject = '';

    connectedCallback() {
        this.initialProcess();
    }
    initialProcess() {
    }
    async handleMaskData() {
        try {
            const result = await maskStandardData();
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

    async handleMaskCustomData() {
        try {
            const payload = this.processMaskData();
            const result = await maskCustomData({ payload: payload });
            if(result.success) {
                this.dispatchEvent(new ShowToastEvent({
                    title: "Get Help",
                    message:
                        "Salesforce documentation is available in the app. Click ? in the upper-right corner.",
                }));
                this.clearData();
            }
        } catch (error) {
            console.log('result', error.message);
        }
    }

    async handleGetObjects() {
        try {
            const result = await getNonSetupObjects();
            if(result !== null || result.length !== 0) {
                this.objectOptions = result.map(object => {
                    return {
                        ...object,
                        label: object.label,
                        value: object.apiName
                    }
                })
            }
        } catch (error) {
            console.error()
        }
    }

    async handleFetchObjectFields(objectApiName) {
        try {
            const result = await getObjectFields({ objectApiName : objectApiName });
            console.log('result: ', result);
            if(result !== null || result.length !== 0) {
                this.fieldOptions = result.map(field => {
                    return {
                        ...field,
                        label: field.label,
                        value: field.apiName,
                        dataType: field.dataType
                    };
                })
            }
        } catch (error) {
            console.log('error occured: ', error);
        }
    }

    async handleAddTile() {
        if(this.tilesList.length === 0) {
            await this.handleGetObjects();
        }
        const newTile = {
            id: this.nextTileId,
            object: '',
            fields: [],
            selectedFieldId: ''
        };
        this.tilesList = [...this.tilesList, newTile];
        this.nextTileId++;
    }

    async handleObjectChange(event) {
        const tileId = parseInt(event.currentTarget.dataset.tileId, 10);
        const tile = this.tilesList.find(t => t.id === tileId);
        const objectApiName = event.detail.value;
        if (tile) {
            tile.object = objectApiName;
            if(tile.fields.length > 0) {
                tile.fields = [];
            }
        }
        
    }

    handleFieldSelect(event) {
        const tileId = parseInt(event.currentTarget.dataset.tileId, 10);
        console.log('tileId: ', tileId);
        const tile = this.tilesList.find(t => t.id === tileId);
        const selectedFieldValue = event.detail.value;
        
        if (tile && selectedFieldValue) {
            const selectedField = this.fieldOptions.find(f => f.value === selectedFieldValue);
            if (selectedField) {
                const fieldExists = tile.fields.some(f => f.value === selectedFieldValue);
                if (!fieldExists) {
                    tile.fields.push({
                        value: selectedField.value,
                        dataType: selectedField.dataType,
                        displayLabel: `${selectedField.label} (${selectedField.value})`
                    });
                }
                tile.selectedFieldId = '';
            }
        }
    }

    async handleFieldFocus(event) {
        const objectName = event.currentTarget.dataset.object;
        if(objectName === this.selectedObject) {
            return;
        }
        console.log('objectName: ', objectName);
        this.selectedObject = objectName;
        this.fields = [];
        await this.handleFetchObjectFields(objectName);
    }

    handleRemoveField(event) {
        const tileId = parseInt(event.currentTarget.dataset.tileId, 10);
        const fieldValue = event.currentTarget.dataset.fieldValue;
        const tile = this.tilesList.find(t => t.id === tileId);
        
        if (tile) {
            tile.fields = tile.fields.filter(f => f.value !== fieldValue);
        }
    }

    processMaskData() {
        const payload = this.tilesList.map(tile => {
            return {
                objectApiName: tile.object,
                fields: tile.fields.map(field => {
                    return {
                        fieldApiName: field.value,
                        fieldDataType: field.dataType
                    }
                })
            }
        })
        return payload;
    }

    clearData() {
        // this.objectOptions = [];
        this.fieldOptions = [];
        this.tilesList = [];
        this.nextTileId = 1;
        this.selectedObject = '';
    }
}