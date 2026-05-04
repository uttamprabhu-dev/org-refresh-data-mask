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
    @track currentPage = 1;

    get totalPages() {
        return this.tilesList.length;
    }

    get displayedTiles() {
        if (this.tilesList.length === 0) return [];
        return [this.tilesList[this.currentPage - 1]];
    }

    get isFirstPage() {
        return this.currentPage <= 1;
    }

    get isLastPage() {
        return this.currentPage >= this.totalPages || this.totalPages === 0;
    }

    get hasTiles() {
        return this.tilesList.length > 0;
    }

    get noTiles() {
        return this.tilesList.length === 0;
    }

    get paginationItems() {
        const items = [];
        const maxPagesToShow = 5;
        const total = this.totalPages;
        const current = this.currentPage;

        if (total <= maxPagesToShow) {
            for (let i = 1; i <= total; i++) {
                items.push({ label: String(i), value: i, isCurrent: i === current });
            }
        } else {
            if (current <= 3) {
                for (let i = 1; i <= 4; i++) items.push({ label: String(i), value: i, isCurrent: i === current });
                items.push({ label: '...', isDots: true });
                items.push({ label: String(total), value: total, isCurrent: total === current });
            } else if (current >= total - 2) {
                items.push({ label: '1', value: 1, isCurrent: 1 === current });
                items.push({ label: '...', isDots: true });
                for (let i = total - 3; i <= total; i++) items.push({ label: String(i), value: i, isCurrent: i === current });
            } else {
                items.push({ label: '1', value: 1, isCurrent: 1 === current });
                items.push({ label: '...', isDots: true });
                items.push({ label: String(current - 1), value: current - 1, isCurrent: false });
                items.push({ label: String(current), value: current, isCurrent: true });
                items.push({ label: String(current + 1), value: current + 1, isCurrent: false });
                items.push({ label: '...', isDots: true });
                items.push({ label: String(total), value: total, isCurrent: false });
            }
        }
        
        return items.map((item, index) => ({
            ...item,
            key: `page_${index}`,
            variant: item.isCurrent ? 'brand' : 'neutral',
            btnClass: item.isCurrent ? 'page-btn page-btn-active' : 'page-btn'
        }));
    }

    async handlePageClick(event) {
        const page = parseInt(event.currentTarget.dataset.page, 10);
        if (page && page !== this.currentPage) {
            this.currentPage = page;
            await this.loadCurrentTileFields();
        }
    }

    async handlePrevious() {
        if (this.currentPage > 1) {
            this.currentPage--;
            await this.loadCurrentTileFields();
        }
    }

    async handleNext() {
        if (this.currentPage < this.totalPages) {
            this.currentPage++;
            await this.loadCurrentTileFields();
        }
    }

    async loadCurrentTileFields() {
        const tile = this.tilesList[this.currentPage - 1];
        if (tile && tile.object) {
            if (this.selectedObject !== tile.object) {
                this.selectedObject = tile.object;
                await this.handleFetchObjectFields(tile.object);
            }
        } else {
            this.fieldOptions = [];
            this.selectedObject = '';
        }
    }

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
            console.log('payload: ', JSON.stringify(payload));
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
                        label: `${field.label} (${field.apiName})`,
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
            objectLabel: '',
            isObjectNotSelected: true,
            fields: [],
            selectedFieldValues: []
        };
        this.tilesList = [...this.tilesList, newTile];
        this.nextTileId++;
        this.currentPage = this.tilesList.length;
        await this.loadCurrentTileFields();
    }

    async handleDeleteTile(event) {
        const tileId = parseInt(event.currentTarget.dataset.tileId, 10);
        this.tilesList = this.tilesList.filter(t => t.id !== tileId);
        
        if (this.tilesList.length === 0) {
            this.clearData();
        } else {
            if (this.currentPage > this.totalPages) {
                this.currentPage = this.totalPages;
            }
            await this.loadCurrentTileFields();
        }
    }

    async handleObjectChange(event) {
        const tileId = parseInt(event.currentTarget.dataset.tileId, 10);
        const tile = this.tilesList.find(t => t.id === tileId);
        const objectApiName = event.detail.value;

        const existingTile = this.tilesList.find(t => t.id !== tileId && t.object === objectApiName);
        if (existingTile && objectApiName) {
            this.dispatchEvent(new ShowToastEvent({
                title: "Info",
                message: "This object has already been selected.",
                variant: "info"
            }));
            this.tilesList = [...this.tilesList];
            return;
        }

        if (tile) {
            tile.object = objectApiName;
            const selectedOption = this.objectOptions.find(o => o.value === objectApiName);
            tile.objectLabel = selectedOption ? selectedOption.label : objectApiName;
            tile.isObjectNotSelected = !objectApiName;
            tile.fields = [];
            tile.selectedFieldValues = [];
            this.selectedObject = objectApiName;
            await this.handleFetchObjectFields(objectApiName);
            this.tilesList = [...this.tilesList];
        }
    }

    handleFieldChange(event) {
        const tileId = parseInt(event.currentTarget.dataset.tileId, 10);
        const tile = this.tilesList.find(t => t.id === tileId);
        const selectedValues = event.detail.value;
        
        if (tile) {
            tile.selectedFieldValues = selectedValues;
            tile.fields = selectedValues.map(val => {
                const fieldDef = this.fieldOptions.find(f => f.value === val);
                return {
                    value: val,
                    dataType: fieldDef ? fieldDef.dataType : '',
                    displayLabel: fieldDef ? fieldDef.label : val
                };
            });
            this.tilesList = [...this.tilesList];
        }
    }

    handleSelectAllFields(event) {
        const tileId = parseInt(event.currentTarget.dataset.tileId, 10);
        const tile = this.tilesList.find(t => t.id === tileId);
        
        if (tile && this.fieldOptions.length > 0) {
            const allFieldValues = this.fieldOptions.map(f => f.value);
            tile.selectedFieldValues = allFieldValues;
            tile.fields = allFieldValues.map(val => {
                const fieldDef = this.fieldOptions.find(f => f.value === val);
                return {
                    value: val,
                    dataType: fieldDef ? fieldDef.dataType : '',
                    displayLabel: fieldDef ? fieldDef.label : val
                };
            });
            this.tilesList = [...this.tilesList];
        }
    }

    processMaskData() {
        const payload = this.tilesList
            .filter(tile => tile.object !== '' && tile.fields && tile.fields.length > 0)
            .map(tile => {
                return {
                    objectApiName: tile.object,
                    fields: tile.fields.map(field => {
                        return {
                            fieldApiName: field.value,
                            fieldDataType: field.dataType
                        }
                    })
                }
            });
        return payload;
    }

    clearData() {
        // this.objectOptions = [];
        this.fieldOptions = [];
        this.tilesList = [];
        this.nextTileId = 1;
        this.selectedObject = '';
        this.currentPage = 1;
    }
}