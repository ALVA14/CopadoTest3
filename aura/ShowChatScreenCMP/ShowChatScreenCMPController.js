/*------------------------------------------------------------
Author:      Sudipta Karmakar
Company:     Salesforce
History
7/30/18  Sudipta Karmakar Init version
------------------------------------------------------------*/
({
    doInit: function (cmp, event, helper) {
        helper.setLiveChatSessionData(cmp, event);
    },
    executecheck: function (cmp, event, helper) {
        helper.setLiveChatDataForSMS(cmp, event);
    }
})