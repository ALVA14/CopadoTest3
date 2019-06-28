/*------------------------------------------------------------
Author:  Sudipta Karmakar
Company: Salesforce
History
7/21/18  Sudipta Karmakar Init version
Commenting

------------------------------------------------------------*/
({
    handleSectionHeaderClick : function(component, event, helper) {
        var button = event.getSource();
        button.set('v.state', !button.get('v.state'));

        var sectionContainer = component.find('collapsibleSectionContainer');
        $A.util.toggleClass(sectionContainer, "slds-is-open");
    }
})