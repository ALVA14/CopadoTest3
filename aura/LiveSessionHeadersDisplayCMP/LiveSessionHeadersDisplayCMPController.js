/*------------------------------------------------------------
Author:  Sudipta Karmakar
Company: Salesforce
History
7/30/18  Sudipta Karmakar Init version
Commenting

------------------------------------------------------------*/
({
    /*------------------------------------------------------------
    Author: Author
    Company: Salesforce
    Description: Load options for combobox
    History
    7/30/18  Sudipta Karmakar Init version
    ------------------------------------------------------------*/
    doInit: function (cmp, event, helper) {
        helper.loadQueueOptions(cmp);
    },

    showSession: function (cmp, event, helper) {
        var sessionData = event.currentTarget.dataset;

        if (sessionData.status !== 'Active') {
            /* don't show ended sessions */
            return;
        }

        helper.showSessionTab(cmp, sessionData.id, sessionData.name);
    },

    handleQueueSelected: function (cmp, event, helper) {
        helper.loadSessions(cmp, event, helper);
    },

    onCometdLoaded: function (component, event, helper) {
        component.set("v.topic", "SmsTextCreated");
        component.set('v.cometd', new org.cometd.CometD());

        var action = component.get('c.getConfiguration');
        action.setCallback(this, function (response) {
            if (component.isValid() && response.getState() === 'SUCCESS') {
                var resp = response.getReturnValue();
                component.set('v.baseUrl', resp.baseUrl);
                component.set('v.sessionId', resp.sessionId);

                if (component.get('v.cometd') != null) {
                    helper.connectCometd(component);
                }
            } else {
                console.error(response);
            }
        });

        $A.enqueueAction(action);
    },

    showhidetab: function (cmp, event, helper) {
        helper.activateTab(cmp, event.currentTarget.dataset.val);
    },

    closetab: function (cmp, event) {
        var tabId = event.getSource().get('v.title');

        cmp.set('v.selectedConversations', cmp.get('v.selectedConversations').filter(function (session) {
            return session.Id !== tabId;
        }));
    }

})