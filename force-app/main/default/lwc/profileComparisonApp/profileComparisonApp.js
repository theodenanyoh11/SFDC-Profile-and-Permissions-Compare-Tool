import { LightningElement, track, wire } from 'lwc';
import getProfiles from '@salesforce/apex/ProfileComparisonController.getProfiles';
import compareProfiles from '@salesforce/apex/ProfileComparisonController.compareProfiles';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';

export default class ProfileComparisonApp extends LightningElement {
    @track profile1Id;
    @track profile2Id;
    @track profileOptions = [];
    @track comparisonResult;
    @track isLoading = false;
    @track filterValue = 'all';

    filterOptions = [
        { label: 'All', value: 'all' },
        { label: 'Differences Only', value: 'differences' }
    ];

    @wire(getProfiles)
    wiredProfiles({ error, data }) {
        if (data) {
            this.profileOptions = data.map(profile => ({
                label: `${profile.profileName} (${profile.userLicenseName || 'N/A'})`,
                value: profile.profileId
            }));
        } else if (error) {
            this.showToast('Error', 'Failed to load profiles', 'error');
        }
    }

    get isCompareDisabled() {
        return !this.profile1Id || !this.profile2Id || this.profile1Id === this.profile2Id || this.isLoading;
    }

    get showDifferencesOnly() {
        return this.filterValue === 'differences';
    }

    get filteredApps() {
        return this.filterData(this.comparisonResult?.assignedApps);
    }

    get filteredObjects() {
        return this.filterData(this.comparisonResult?.objectSettings);
    }

    get filteredSystemPerms() {
        return this.filterData(this.comparisonResult?.systemPermissions);
    }

    get filteredApexClasses() {
        return this.filterData(this.comparisonResult?.apexClasses);
    }

    get filteredVfPages() {
        return this.filterData(this.comparisonResult?.vfPages);
    }

    get filteredCustomPerms() {
        return this.filterData(this.comparisonResult?.customPermissions);
    }

    // Tab labels with difference counts
    get appsTabLabel() {
        const s = this.comparisonResult?.summary;
        return s ? `Assigned Apps (${s.differentApps})` : 'Assigned Apps';
    }

    get objectsTabLabel() {
        const s = this.comparisonResult?.summary;
        return s ? `Object Settings (${s.differentObjects})` : 'Object Settings';
    }

    get sysPermsTabLabel() {
        const s = this.comparisonResult?.summary;
        return s ? `System Permissions (${s.differentSystemPerms})` : 'System Permissions';
    }

    get apexTabLabel() {
        const s = this.comparisonResult?.summary;
        return s ? `Apex Classes (${s.differentApexClasses})` : 'Apex Classes';
    }

    get vfTabLabel() {
        const s = this.comparisonResult?.summary;
        return s ? `Visualforce Pages (${s.differentVfPages})` : 'Visualforce Pages';
    }

    get customPermsTabLabel() {
        const s = this.comparisonResult?.summary;
        return s ? `Custom Permissions (${s.differentCustomPerms})` : 'Custom Permissions';
    }

    get summaryCards() {
        if (!this.comparisonResult?.summary) return [];
        const s = this.comparisonResult.summary;
        return [
            { label: 'Apps', total: s.totalApps, different: s.differentApps, cssClass: this.getCardClass(s.differentApps) },
            { label: 'Objects', total: s.totalObjects, different: s.differentObjects, cssClass: this.getCardClass(s.differentObjects) },
            { label: 'System Perms', total: s.totalSystemPerms, different: s.differentSystemPerms, cssClass: this.getCardClass(s.differentSystemPerms) },
            { label: 'Apex', total: s.totalApexClasses, different: s.differentApexClasses, cssClass: this.getCardClass(s.differentApexClasses) },
            { label: 'VF Pages', total: s.totalVfPages, different: s.differentVfPages, cssClass: this.getCardClass(s.differentVfPages) },
            { label: 'Custom Perms', total: s.totalCustomPerms, different: s.differentCustomPerms, cssClass: this.getCardClass(s.differentCustomPerms) }
        ];
    }

    getCardClass(differences) {
        return differences > 0
            ? 'slds-box slds-theme_warning slds-text-align_center'
            : 'slds-box slds-theme_success slds-text-align_center';
    }

    filterData(data) {
        if (!data) return [];
        if (this.showDifferencesOnly) {
            return data.filter(item => item.isDifferent);
        }
        return [...data];
    }

    handleProfile1Change(event) {
        this.profile1Id = event.detail.value;
    }

    handleProfile2Change(event) {
        this.profile2Id = event.detail.value;
    }

    handleFilterChange(event) {
        this.filterValue = event.detail.value;
    }

    async handleCompare() {
        this.isLoading = true;
        this.comparisonResult = null;
        try {
            this.comparisonResult = await compareProfiles({
                profileId1: this.profile1Id,
                profileId2: this.profile2Id
            });
        } catch (error) {
            this.showToast('Error', error.body?.message || 'Comparison failed', 'error');
        } finally {
            this.isLoading = false;
        }
    }

    showToast(title, message, variant) {
        this.dispatchEvent(new ShowToastEvent({ title, message, variant }));
    }
}
