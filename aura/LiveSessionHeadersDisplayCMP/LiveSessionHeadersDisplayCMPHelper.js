/*------------------------------------------------------------
Author:      Sudipta Karmakar
Company:     Salesforce
History
7/30/18  Sudipta Karmakar Init version
------------------------------------------------------------*/

({
    loadSessions: function (cmp) {
        var action = cmp.get("c.getActiveSessions");
        var helper = this;

        console.log('SELECTED ID: ' + cmp.get('v.selectedQueue'));

        action.setParams({queueId: cmp.get('v.selectedQueue')});
        action.setCallback(this, function (response) {
            var state = response.getState();
            if (state === "SUCCESS") {
                //console.log(response.getReturnValue());
                cmp.set("v.livesessions", response.getReturnValue());
                helper.buildConversationsByAgentList(cmp);
            } else if (state === "INCOMPLETE") {
                /* nothing to do for now */
            } else if (state === "ERROR") {
                var errors = response.getError();
                if (errors) {
                    if (errors[0] && errors[0].message) {
                        console.log("Error message: " + errors[0].message);
                    }
                } else {
                    console.log("Unknown error");
                }
            }
        });

        $A.enqueueAction(action);
    },

    showSessionTab: function (cmp, id, label) {
        var listSelectedSessions = cmp.get('v.selectedConversations');

        for (var i = 0; i < listSelectedSessions.length; i++) {
            if (listSelectedSessions[i].Id === id) {
                this.activateTab(cmp, id);
                return;
            }
        }

        /* hide other tabs, the new one will be auto-activated */
        this.hideAllTabs(cmp);

        listSelectedSessions.push({
            Id: id,
            Name: label
        });

        cmp.set('v.selectedConversations', listSelectedSessions);

    },

    connectCometd: function (component) {
        var helper = this;

        // Configure CometD
        var cometdUrl = component.get('v.baseUrl') + '/cometd/40.0/';
        var cometd = component.get('v.cometd');

        cometd.configure({
            url: cometdUrl,
            requestHeaders: {Authorization: 'OAuth ' + component.get('v.sessionId')},
            appendMessageTypeToURL: false
        });

        cometd.websocketEnabled = false;

        // Establish CometD connection
        console.log('Connecting to CometD: ' + cometdUrl);

        cometd.handshake(function (handshakeReply) {
            if (handshakeReply.successful) {
                console.log('Connected to CometD.');
                cometd.subscribe('/topic/' + component.get("v.topic"),
                    $A.getCallback(function (platformEvent) {
                        var childComponent = component.find('ChatScreens');
                        if (childComponent && childComponent.length) {
                            for (var i = 0; i < childComponent.length; i++) {
                                childComponent[i].myCheckMethod((platformEvent));
                            }
                        } else if (childComponent) {
                            childComponent.myCheckMethod((platformEvent));
                        }
                    })
                );
                cometd.subscribe('/topic/NewConversationHeader',
                    $A.getCallback(function (platformEvent) {
                        var sendDataBack = JSON.stringify(component.get('v.livesessions'));

                        console.log('ConversationHeader', JSON.stringify(platformEvent));
                        console.log('the Data to send back', sendDataBack);

                        var affectedSession = platformEvent.data.sobject;

                        if (affectedSession.LiveText__Status__c === 'Active') {
                            var action = component.get("c.getNewActiveSessions");

                            action.setParams({
                                SessionId: affectedSession.Id,
                                Response: sendDataBack,
                                selectedQueue: component.get("v.selectedQueue")
                            });

                            action.setCallback(this, function (response) {
                                var state = response.getState();
                                if (state === "SUCCESS") {
                                    component.set('v.livesessions', response.getReturnValue());
                                    helper.buildConversationsByAgentList(component);
                                } else if (state === "INCOMPLETE") {
                                    /* nothing to do for now */
                                } else if (state === "ERROR") {
                                    var errors = response.getError();
                                    if (errors) {
                                        if (errors[0] && errors[0].message) {
                                            console.log("Error message: " + errors[0].message);
                                        }
                                    } else {
                                        console.log("Unknown error");
                                    }
                                }
                            });

                            $A.enqueueAction(action);
                        } else if (affectedSession.LiveText__Status__c === 'Ended') {
                            var sessions = component.get("v.livesessions");

                            if (sessions[affectedSession.LiveText__AcceptedBy__c]) {
                                sessions[affectedSession.LiveText__AcceptedBy__c] = sessions[affectedSession.LiveText__AcceptedBy__c].filter(function (session) {
                                    return session.Id !== affectedSession.Id;
                                });
                            }

                            component.set("v.livesessions", sessions);

                            helper.buildConversationsByAgentList(component);

                            var selectedConversations = component.get('v.selectedConversations');
                            if (selectedConversations && selectedConversations.length) {
                                component.set('v.selectedConversations', selectedConversations.filter(function (session) {
                                    return session.Id !== affectedSession.Id;
                                }));
                            }
                        }
                    })
                );
            } else {
                console.error('Failed to connected to CometD.');
            }
        });
    },

    buildConversationsByAgentList: function (cmp) {
        console.log('Get Value', cmp.get("v.livesessions"));

        var sessionMap = [];
        var sessions = cmp.get("v.livesessions");

        for (var agent in sessions) {
            if (sessions.hasOwnProperty(agent)) {
                sessionMap.push({agent: agent, value: sessions[agent]});
            }
        }

        cmp.set('v.conversationsByAgent', sessionMap);
    },

    activateTab: function (cmp, tabId) {
        var navItems = cmp.find('tabidscreated');

        if ($A.util.isArray(navItems)) {
            for (var i = 0; i < navItems.length; i++) {
                console.log('nav item', navItems[i], navItems[i].getElement());
                if (tabId === navItems[i].getElement().getAttribute('title')) {
                    $A.util.addClass(navItems[i], 'slds-active');
                } else {
                    $A.util.removeClass(navItems[i], 'slds-active');
                }
            }
        }

        var tabs = cmp.find('TabidsData');

        if ($A.util.isArray(tabs)) {
            for (var i = 0; i < tabs.length; i++) {
                console.log('tab', tabs[i], tabs[i].getElement());
                if (tabId === tabs[i].getElement().getAttribute('title')) {
                    $A.util.removeClass(tabs[i], 'slds-hide');
                    $A.util.addClass(tabs[i], 'slds-show');
                } else {
                    $A.util.removeClass(tabs[i], 'slds-show');
                    $A.util.addClass(tabs[i], 'slds-hide');
                }

            }
        }
    },

    hideAllTabs: function (cmp) {
        var navItems = cmp.find('tabidscreated');
        if ($A.util.isArray(navItems)) {
            for (var i = 0; i < navItems.length; i++) {
                $A.util.removeClass(navItems[i], 'slds-active');
            }
        } else {
            $A.util.removeClass(navItems, 'slds-active');
        }

        var tabs = cmp.find('TabidsData');
        if ($A.util.isArray(tabs)) {
            for (var i = 0; i < tabs.length; i++) {

                $A.util.removeClass(tabs[i], 'slds-show');
                $A.util.addClass(tabs[i], 'slds-hide');
            }
        } else {
            $A.util.removeClass(tabs, 'slds-show');
            $A.util.addClass(tabs, 'slds-hide');
        }
    },

    loadQueueOptions: function (cmp) {
        var action = cmp.get("c.getLiveQueues");
        var helper = this;

        action.setCallback(this, function (response) {
            var state = response.getState();
            if (state === "SUCCESS") {
                var options = response.getReturnValue();
                cmp.set("v.queueOptions", options);

                if (options.length) {
                    cmp.set("v.selectedQueue", options[0].value);
                    helper.loadSessions(cmp);
                }
            }
        });

        $A.enqueueAction(action);
    }
})