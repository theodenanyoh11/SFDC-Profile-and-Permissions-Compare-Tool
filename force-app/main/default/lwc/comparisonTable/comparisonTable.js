import { LightningElement, api } from 'lwc';

export default class ComparisonTable extends LightningElement {
    @api profile1Name;
    @api profile2Name;

    _data = [];

    @api
    get data() {
        return this._data;
    }

    set data(value) {
        this._data = (value || []).map(row => ({
            ...row,
            rowClass: row.isDifferent ? 'slds-hint-parent highlight-row' : 'slds-hint-parent'
        }));
    }

    get processedData() {
        return this._data;
    }

    get hasData() {
        return this._data && this._data.length > 0;
    }
}
