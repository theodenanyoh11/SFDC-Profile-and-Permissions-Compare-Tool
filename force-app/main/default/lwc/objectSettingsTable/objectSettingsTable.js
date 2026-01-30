import { LightningElement, api, track } from 'lwc';
import getFieldComparison from '@salesforce/apex/ProfileComparisonController.getFieldComparison';

export default class ObjectSettingsTable extends LightningElement {
    @api profile1Name;
    @api profile2Name;
    @api profile1Id;
    @api profile2Id;
    @api showDifferencesOnly = false;

    @track _expandedObjects = {};
    @track _flsData = {};
    @track _loadingFls = {};

    _data = [];

    @api
    get data() {
        return this._data;
    }

    set data(value) {
        this._data = value || [];
        // Reset expansion state when data changes
        this._expandedObjects = {};
        this._flsData = {};
        this._loadingFls = {};
    }

    get profile1CrudHeader() {
        return this.profile1Name ? `${this.profile1Name} (CRUD)` : 'Profile 1 (CRUD)';
    }

    get profile2CrudHeader() {
        return this.profile2Name ? `${this.profile2Name} (CRUD)` : 'Profile 2 (CRUD)';
    }

    get hasData() {
        return this._data && this._data.length > 0;
    }

    get processedData() {
        return this._data.map(row => {
            const isExpanded = this._expandedObjects[row.objectName] === true;
            const flsComparisons = this._flsData[row.objectName] || [];

            // Filter FLS if showing differences only
            let filteredFls = flsComparisons;
            if (this.showDifferencesOnly && flsComparisons.length > 0) {
                filteredFls = flsComparisons.filter(f => f.isDifferent);
            }

            // Add rowClass to FLS data for the nested comparison table
            const processedFls = filteredFls.map(f => ({
                ...f,
                rowClass: f.isDifferent ? 'slds-hint-parent highlight-row' : 'slds-hint-parent'
            }));

            return {
                ...row,
                rowClass: row.isDifferent ? 'slds-hint-parent highlight-row' : 'slds-hint-parent',
                expandIcon: isExpanded ? 'utility:chevrondown' : 'utility:chevronright',
                isExpanded: isExpanded,
                flsKey: row.objectName + '_fls',
                isLoadingFls: this._loadingFls[row.objectName] === true,
                fieldComparisons: processedFls
            };
        });
    }

    async handleToggleFls(event) {
        const objectName = event.currentTarget.dataset.object;

        if (this._expandedObjects[objectName]) {
            // Collapse
            this._expandedObjects = { ...this._expandedObjects, [objectName]: false };
        } else {
            // Expand
            this._expandedObjects = { ...this._expandedObjects, [objectName]: true };

            // Load FLS if not already loaded
            if (!this._flsData[objectName]) {
                await this.loadFlsData(objectName);
            }
        }
    }

    async loadFlsData(objectName) {
        this._loadingFls = { ...this._loadingFls, [objectName]: true };

        try {
            const result = await getFieldComparison({
                profileId1: this.profile1Id,
                profileId2: this.profile2Id,
                objectName: objectName
            });
            this._flsData = { ...this._flsData, [objectName]: result };
        } catch (error) {
            console.error('Error loading FLS for ' + objectName + ':', error);
            this._flsData = { ...this._flsData, [objectName]: [] };
        } finally {
            this._loadingFls = { ...this._loadingFls, [objectName]: false };
        }
    }
}
