/*------------------------------------------------------------
Author:      Sudipta Karmakar
Company:     Salesforce
History
7/30/18  Sudipta Karmakar Init version
------------------------------------------------------------*/
({
    setLiveChatSessionData: function (cmp, event) {
        var livesessionid = cmp.get('v.livesessionid');
        console.log('Session Id got', livesessionid);

        var action = cmp.get('c.getConversationData');
        action.setParams({SessionId: livesessionid});

        action.setCallback(this, function (response) {
            var state = response.getState();
            if (state === 'SUCCESS') {
                var resp = JSON.parse(response.getReturnValue());
                var conversation = resp[0];
                cmp.set('v.livesessiondata', conversation);


                conversation.LiveText__SMS_Text__r.records.forEach(function (element) {
                    if (element.LiveText__Message__c.indexOf('servlet.FileDownload') > -1) {
                        var str = element.LiveText__Message__c;
                        element.Image = str.match(/href="(.*?)"/i)[1];
                    }
                });

                cmp.set('v.livechatdata', conversation.LiveText__SMS_Text__r.records);
            } else if (state === 'INCOMPLETE') {
                console.log('incomplete');
            } else if (state === 'ERROR') {
                var errors = response.getError();

                if (errors) {
                    if (errors[0] && errors[0].message) {
                        console.log('Error message: ' + errors[0].message);
                    }
                } else {
                    console.log('Unknown error');
                }
            }
        });

        $A.enqueueAction(action);
    },

    setLiveChatDataForSMS: function (cmp, event) {
        var params = event.getParam('arguments');
        console.log('message data', JSON.stringify(params.message.channel));

        if (params.message.channel === '/topic/SmsTextCreated' &&
            params.message.data.sobject.LiveText__Conversation_Header__c === cmp.get('v.livesessionid')) {

            var action = cmp.get('c.getSmsData');

            action.setParams({SmsId: params.message.data.sobject.Id});

            action.setCallback(this, function (response) {
                var state = response.getState();

                if (state === 'SUCCESS') {
                    var content = JSON.parse(response.getReturnValue());

                    console.log('sms text content', content)

                    var allChatdata = cmp.get('v.livechatdata');

                    allChatdata.push(content[0]);

                    cmp.set('v.livechatdata', allChatdata);

                    console.log('Set Data', cmp.get('v.livechatdata'));
                } else if (state === 'INCOMPLETE') {
                    console.log('incomplete');
                } else if (state === 'ERROR') {
                    var errors = response.getError();
                    if (errors) {
                        if (errors[0] && errors[0].message) {
                            console.log('Error message: ' + errors[0].message);
                        }
                    } else {
                        console.log('Unknown error');
                    }
                }
            });

            $A.enqueueAction(action);
        }
    }
})