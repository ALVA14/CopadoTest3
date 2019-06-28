/*------------------------------------------------------------
Author:      Sudipta Karmakar
Company:     Salesforce
History
7/21/18  Sudipta Karmakar Init version
------------------------------------------------------------*/
({
    doInit: function (cmp, event, helper) {
        helper.getCustomerData(cmp, event);
    }
})