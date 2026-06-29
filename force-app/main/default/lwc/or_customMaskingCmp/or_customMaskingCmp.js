import { LightningElement, track } from 'lwc';
import maskCustomData from '@salesforce/apex/PostRefreshOrgProcessController.maskCustomData';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import getNonSetupObjects from '@salesforce/apex/ObjectDataHelper.getNonSetupObjects';
import getObjectFields from '@salesforce/apex/ObjectDataHelper.getObjectFields';

export default class Or_customMaskingCmp extends LightningElement {
    static MAX_SELECTED_FIELDS = 25;

    @track fieldOptions = [];
    @track tilesList = [];
    @track nextTileId = 1;
    @track selectedObject = '';
    @track currentPage = 1;

    _searchTimers = {};
    _allObjects = null;

    async loadAllObjects() {
        if (this._allObjects === null || this._allObjects.length <= 0) {
            this._allObjects = await getNonSetupObjects();
        }
        return this._allObjects;
    }

    searchObjects(searchTerm) {
        if (!this._allObjects) return [];
        const lower = searchTerm.toLowerCase();
        return this._allObjects.filter(obj =>
            obj.label.toLowerCase().includes(lower) ||
            obj.apiName.toLowerCase().includes(lower)
        );
    }

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

    async handleMaskCustomData() {
        try {
            const payload = this.processMaskData();
            console.log('payload: ', JSON.stringify(payload));
            const result = await maskCustomData({ payload: payload });
            if (result.success) {
                this.dispatchEvent(new ShowToastEvent({
                    title: "Batch Class has been initialized",
                    message: "Please check the Apex Jobs for the running batch jobs.",
                    variant: "info"
                }));
                this.clearData();
            }
        } catch (error) {
            console.log('result', error.message);
        }
    }

    async handleFetchObjectFields(objectApiName) {
        try {
            const result = await getObjectFields({ objectApiName: objectApiName, operationType: 'custom-masking' });
            console.log('result: ', result);
            if (result !== null || result.length !== 0) {
                this.fieldOptions = result.map(field => {
                    return {
                        ...field,
                        label: `${field.label} (${field.apiName})`,
                        value: field.apiName,
                        dataType: field.dataType
                    };
                });
            }
        } catch (error) {
            console.log('error occured: ', error);
        }
    }

    async handleAddTile() {
        const newTile = {
            id: this.nextTileId,
            object: '',
            objectLabel: '',
            isObjectNotSelected: true,
            fields: [],
            selectedFieldValues: [],
            objectSearchTerm: '',
            objectSearchResults: [],
            showObjectDropdown: false,
            isObjectSearching: false,
            showNoObjectResults: false
        };
        this.tilesList = [...this.tilesList, newTile];
        this.nextTileId++;
        this.currentPage = this.tilesList.length;
        await this.loadCurrentTileFields();
    }

    async handleDeleteTile(event) {
        const tileId = parseInt(event.currentTarget.dataset.tileId, 10);
        if (this._searchTimers[tileId]) {
            clearTimeout(this._searchTimers[tileId]);
            delete this._searchTimers[tileId];
        }
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

    handleObjectSearch(event) {
        const tileId = parseInt(event.currentTarget.dataset.tileId, 10);
        const searchTerm = event.target.value;

        const tile = this.tilesList.find(t => t.id === tileId);
        if (!tile) return;

        tile.objectSearchTerm = searchTerm;
        tile.object = '';
        tile.objectLabel = '';
        tile.isObjectNotSelected = true;
        tile.fields = [];
        tile.selectedFieldValues = [];

        if (!searchTerm || searchTerm.trim().length < 1) {
            tile.showObjectDropdown = false;
            tile.objectSearchResults = [];
            tile.showNoObjectResults = false;
            this.tilesList = [...this.tilesList];
            return;
        }

        tile.isObjectSearching = true;
        tile.showObjectDropdown = true;
        tile.showNoObjectResults = false;
        this.tilesList = [...this.tilesList];

        if (this._searchTimers[tileId]) {
            clearTimeout(this._searchTimers[tileId]);
        }

        this._searchTimers[tileId] = setTimeout(async () => {
            try {
                await this.loadAllObjects();
                const results = this.searchObjects(searchTerm.trim());
                const t = this.tilesList.find(tile => tile.id === tileId);
                if (t && t.objectSearchTerm === searchTerm) {
                    t.objectSearchResults = results;
                    t.isObjectSearching = false;
                    t.showNoObjectResults = results.length === 0;
                    this.tilesList = [...this.tilesList];
                }
            } catch (error) {
                const t = this.tilesList.find(tile => tile.id === tileId);
                if (t) {
                    t.isObjectSearching = false;
                    t.objectSearchResults = [];
                    t.showNoObjectResults = false;
                    this.tilesList = [...this.tilesList];
                }
            }
        }, 300);
    }

    handleObjectSearchBlur(event) {
        const tileId = parseInt(event.currentTarget.dataset.tileId, 10);
        setTimeout(() => {
            const tile = this.tilesList.find(t => t.id === tileId);
            if (tile) {
                tile.showObjectDropdown = false;
                if (!tile.object) {
                    tile.objectSearchTerm = '';
                    tile.objectSearchResults = [];
                    tile.showNoObjectResults = false;
                }
                this.tilesList = [...this.tilesList];
            }
        }, 200);
    }

    async handleObjectSelect(event) {
        const tileId = parseInt(event.currentTarget.dataset.tileId, 10);
        const apiName = event.currentTarget.dataset.apiName;
        const label = event.currentTarget.dataset.label;

        const existingTile = this.tilesList.find(t => t.id !== tileId && t.object === apiName);
        if (existingTile) {
            this.dispatchEvent(new ShowToastEvent({
                title: "Info",
                message: "This object has already been selected.",
                variant: "info"
            }));
            return;
        }

        const tile = this.tilesList.find(t => t.id === tileId);
        if (tile) {
            tile.object = apiName;
            tile.objectLabel = label;
            tile.objectSearchTerm = label;
            tile.isObjectNotSelected = false;
            tile.showObjectDropdown = false;
            tile.objectSearchResults = [];
            tile.showNoObjectResults = false;
            tile.fields = [];
            tile.selectedFieldValues = [];
            this.selectedObject = apiName;
            this.tilesList = [...this.tilesList];
            await this.handleFetchObjectFields(apiName);
            this.tilesList = [...this.tilesList];
        }
    }

    handleFieldChange(event) {
        const tileId = parseInt(event.currentTarget.dataset.tileId, 10);
        let selectedValues = [...event.detail.value]; // clone to avoid shared reference

        if (selectedValues.length > Or_customMaskingCmp.MAX_SELECTED_FIELDS) {
            selectedValues = selectedValues.slice(0, Or_customMaskingCmp.MAX_SELECTED_FIELDS);
            this.dispatchEvent(new ShowToastEvent({
                title: 'Field Limit Reached',
                message: `You can select a maximum of ${Or_customMaskingCmp.MAX_SELECTED_FIELDS} fields per object.`,
                variant: 'warning'
            }));
        }

        const newFields = selectedValues.map(val => {
            const fieldDef = this.fieldOptions.find(f => f.value === val);
            return {
                value: val,
                dataType: fieldDef ? fieldDef.dataType : '',
                displayLabel: fieldDef ? fieldDef.label : val
            };
        });

        this.tilesList = this.tilesList.map(t =>
            Number(t.id) === tileId
                ? { ...t, selectedFieldValues: selectedValues, fields: newFields }
                : t
        );
    }

    handleSelectAllFields(event) {
        const tileId = parseInt(event.currentTarget.dataset.tileId, 10);
        const tile = this.tilesList.find(t => t.id === tileId);

        if (tile && this.fieldOptions.length > 0) {
            const allFieldValues = this.fieldOptions
                .map(f => f.value)
                .slice(0, Or_customMaskingCmp.MAX_SELECTED_FIELDS);
            const newFields = allFieldValues.map(val => {
                const fieldDef = this.fieldOptions.find(f => f.value === val);
                return {
                    value: val,
                    dataType: fieldDef ? fieldDef.dataType : '',
                    displayLabel: fieldDef ? fieldDef.label : val
                }(automation_disabled)            });
            this.tilesList = this.tilesList.map(t =>
                Number(t.id) === tileId
                    ? { ...t, selectedFieldValues: allFieldValues, fields: newFields }
                    : t
            );
        }
    }

    processMaskData() {
        console.log('Tiles list', this.tilesList);
        
        return this.tilesList
            .filter(tile => tile.object !== '' && tile.fields && tile.fields.length > 0)
            .map(tile => ({
                objectApiName: tile.object,
                fields: tile.fields.map(field => ({
                    fieldApiName: field.value,
                    fieldDataType: field.dataType
                }))
            }));
    }

    clearData() {
        this.fieldOptions = [];
        this.tilesList = [];
        this.nextTileId = 1;
        this.selectedObject = '';
        this.currentPage = 1;
        this._searchTimers = {};
    }
}