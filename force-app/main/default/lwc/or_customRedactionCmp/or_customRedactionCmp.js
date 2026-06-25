import { LightningElement, track } from 'lwc';
import getNonSetupObjects from '@salesforce/apex/ObjectDataHelper.getNonSetupObjects'

export default class Or_customRedactionCmp extends LightningElement {
    _allObjects = null;

    async loadAllObjects() {
        if(this._allObjects === null || this._allObjects <= 0) {
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
}