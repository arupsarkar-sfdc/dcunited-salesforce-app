import { LightningElement, api, wire, track } from 'lwc';
import getDataGraphInfo from '@salesforce/apex/RealTimeAnalyticsController.getDataGraphInfo';

export default class RealTimeProfileEngagement extends LightningElement {
    @api recordId;
    @track activities = [];
    @track activeTab = 'browse';
    @track isLoading = true;
    @track error;
    @track sourceId = '';
    @track isExpanded = {};
    @track browseCssClass = 'slds-tabs_default__item slds-is-active';
    @track cartCssClass = 'slds-tabs_default__item';    

    handleSourceIdChange(event) {
        this.sourceId = event.target.value;
        this.loadData();
    }

    handleRefresh() {
        this.loadData();
    }
    handleToggleDetails(event) {
        const activityId = event.currentTarget.dataset.id;
        this.isExpanded[activityId] = !this.isExpanded[activityId];
    }    

    loadData() {
        if (this.sourceId) {
            getDataGraphInfo({ sourceRecordId: this.sourceId })
                .then(result => {
                    this.processData(result);
                })
                .catch(error => {
                    this.error = error.message;
                })
                .finally(() => {
                    this.isLoading = false;
                });
        }
    }

    processData(data) {
        try {
            const parsedData = JSON.parse(data);
            console.log('parsedData:', JSON.stringify(parsedData));
            if (parsedData.customerProfile) {
                this.activities = [];
                
                console.log('parsedData.customerProfile:', JSON.stringify(parsedData.customerProfile));
                console.log('parsedData.customerProfile.productBrowse:', JSON.stringify(parsedData.customerProfile.productBrowse));
                console.log('parsedData.customerProfile.shoppingCart:', JSON.stringify(parsedData.customerProfile.shoppingCart));

                // Process browse engagements
                if (parsedData.customerProfile.productBrowse) {
                    parsedData.customerProfile.productBrowse.forEach(browse => {
                        this.activities.push({
                            id: browse.browseEngagementId,
                            title: `Product Browse: ${browse.browseEngagementName}`,
                            description: `Viewed product ${browse.browseProductId}`,
                            createdDate: browse.browseCreatedDate,
                            iconName: 'standard:catalog',
                            type: 'browse',
                            details: {
                                engagementType: browse.browseEngagementType,
                                channelAction: browse.browseEngagementChannelActionId
                            }
                        });
                    });
                }

                // Process cart engagements
                if (parsedData.customerProfile.shoppingCart) {
                    parsedData.customerProfile.shoppingCart.forEach(cart => {
                        this.activities.push({
                            id: cart.cartEngagementId,
                            title: `Shopping Cart: ${cart.cartProductId}`,
                            description: `Added ${cart.cartProductQuantity} item(s) at $${this.formatPrice(cart.cartProductPrice)}`,
                            createdDate: cart.cartCreatedDate,
                            iconName: 'standard:orders',
                            type: 'cart',
                            details: {
                                quantity: cart.cartProductQuantity,
                                price: this.formatPrice(cart.cartProductPrice)
                            }
                        });
                    });
                }
                
                // Sort activities by date
                this.activities.sort((a, b) => new Date(b.createdDate) - new Date(a.createdDate));
            }            
            // if (parsedData.data && parsedData.data.length > 0) {
            //     const jsonBlob = JSON.parse(parsedData.data[0].json_blob__c);
            //     if (jsonBlob.UnifiedLinkssotIndividualI1__dlm) {
            //         const individual = jsonBlob.UnifiedLinkssotIndividualI1__dlm[0].ssot__Individual__dlm[0];
                    
            //         // Process browse engagements
            //         if (individual.ssot__ProductBrowseEngagement__dlm) {
            //             individual.ssot__ProductBrowseEngagement__dlm.forEach(browse => {
            //                 this.activities.push({
            //                     id: browse.ssot__Id__c,
            //                     title: `Product Browse: ${browse.ssot__Name__c}`,
            //                     description: `Viewed product ${browse.ssot__ProductId__c} on ${browse.ssot__EngagementChannelId__c}`,
            //                     createdDate: this.formatDate(browse.ssot__CreatedDate__c),
            //                     iconName: 'standard:product',
            //                     type: 'browse'
            //                 });
            //             });
            //         }

            //         // Process cart engagements
            //         if (individual.ssot__ShoppingCartEngagement__dlm) {
            //             individual.ssot__ShoppingCartEngagement__dlm.forEach(cart => {
            //                 this.activities.push({
            //                     id: cart.ssot__Id__c,
            //                     title: `Shopping Cart: ${cart.ssot__ProductId__c}`,
            //                     description: `Added ${cart.ssot__ProductQuantity__c} item(s) at $${cart.ssot__ProductPriceAmount__c}`,
            //                     createdDate: this.formatDate(cart.ssot__CreatedDate__c),
            //                     iconName: 'standard:cart',
            //                     type: 'cart'
            //                 });
            //             });
            //         }
            //     }
            // }
            //this.activities.sort((a, b) => new Date(b.createdDate) - new Date(a.createdDate));
        } catch (error) {
            console.error('Error processing data:', error);
            this.error = error.message;
        }
    }

    get filteredActivities() {
        // return this.activities.filter(activity => activity.type === this.activeTab);
        return this.activities
        .filter(activity => activity.type === this.activeTab)
        .map(activity => ({
            ...activity,
            iconName: activity.type === 'cart' ? 'standard:orders' : 'standard:catalog'
        }));        
    }

    handleTabClick(event) {
        // this.activeTab = event.currentTarget.dataset.tab;
        const selectedTab = event.currentTarget.dataset.tab;
        this.activeTab = selectedTab;
        this.browseCssClass = `slds-tabs_default__item ${selectedTab === 'browse' ? 'slds-is-active' : ''}`;
        this.cartCssClass = `slds-tabs_default__item ${selectedTab === 'cart' ? 'slds-is-active' : ''}`;        
    }

    formatDate(dateString) {
        return new Intl.DateTimeFormat('en-US', {
            year: 'numeric',
            month: 'short',
            day: '2-digit',
            hour: '2-digit',
            minute: '2-digit'
        }).format(new Date(dateString));
    }

    formatPrice(amount) {
        return Number(amount).toFixed(2);
    }
}
