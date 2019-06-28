/*------------------------------------------------------------
Author:      Pavel Usoltsev
Company:     Salesforce
Description: A utility class for the SMS text trigger
Inputs:      Triggered live text messages
Test Class:  SMSTextHandler_Test

History
7/26/18     Pavel Usoltsev   Initial Version
21/01/19    Pavel Kalinin    Implemented MOS-220/MOS-227
22/02/19    Sven Kretschmann fixes MOS-456, setting conversation last message timestamps properly
------------------------------------------------------------*/
public with sharing class SMSTextHandler extends TriggerHandler {

    public SMSTextHandler() {
        this.setMaxLoopCount(5);
    }

    protected override void beforeInsert() {
        TriggerHandler.bypass('LiveMessageSessionHandler');
    }

    protected override void afterInsert() {
        this.triggerAutoResponseMessage(Trigger.new, null);
        this.updateConversationTimestamps(Trigger.new, null);
    }

    protected override void afterUpdate() {
        //this method is used to send a hello message after first message from customer
        //as his/her first message is inserted with empty session id (LiveText__Conversation_Header__c) and then is updated

        this.triggerAutoResponseMessage(Trigger.new, (Map<Id, LiveText__SMS_Text__c>) Trigger.oldMap);
        this.updateConversationTimestamps(Trigger.new, (Map<Id, LiveText__SMS_Text__c>) Trigger.oldMap);
    }

    /**
     * Check if the messages have a conversation assigned, are inbound and if yes, enqueue the auto response job.
     *
     * @param messages
     * @param oldMessages
     */
    private void triggerAutoResponseMessage(List<LiveText__SMS_Text__c> messages, Map<Id, LiveText__SMS_Text__c> oldMessages) {
        List<LiveText__SMS_Text__c> newInboundMessages = new List<LiveText__SMS_Text__c>();

        for (LiveText__SMS_Text__c message : messages) {
            LiveText__SMS_Text__c oldMessage = oldMessages != null ? oldMessages.get(message.Id) : null;

            if (message.LiveText__Sent_To_Customer__c) {
                /* it's outbound */
                continue;
            }

            if (!this.isNewlyAssignedToConversation(message, oldMessage)) {
                /* not assigned to a conversation yet or already was */
                continue;
            }

            if (message.LiveText__Source__c == 'Salesforce') {
                /* system message */
                continue;
            }

            newInboundMessages.add(message);
        }

        if (!newInboundMessages.isEmpty()) {
            System.enqueueJob(new SendMessageJob(newInboundMessages));
        }
    }

    /**
     * Update the conversation timestamps tracking the last sent and received message
     *
     * @param messages
     * @param oldMessages
     */
    private void updateConversationTimestamps(List<LiveText__SMS_Text__c> messages, Map<Id, LiveText__SMS_Text__c> oldMessages) {
        Map<Id, List<LiveText__SMS_Text__c>> messagesByConversationId = new Map<Id, List<LiveText__SMS_Text__c>>();

        for (LiveText__SMS_Text__c message : messages) {
            LiveText__SMS_Text__c oldMessage = oldMessages != null ? oldMessages.get(message.Id) : null;

            if (!this.isNewlyAssignedToConversation(message, oldMessage)) {
                continue;
            }

            if (!messagesByConversationId.containsKey(message.LiveText__Conversation_Header__c)) {
                messagesByConversationId.put(message.LiveText__Conversation_Header__c, new List<LiveText__SMS_Text__c>());
            }

            messagesByConversationId.get(message.LiveText__Conversation_Header__c).add(message);
        }

        if (messagesByConversationId.isEmpty()) {
            return;
        }

        List<LiveText__Conversation_Header__c> conversations = [
            SELECT
                Id,
                LiveText__Status__c,
                AgentReplyPendingSince__c
            FROM
                LiveText__Conversation_Header__c
            WHERE
                Id IN :messagesByConversationId.keySet()
        ];

        Map<Id, LiveText__Conversation_Header__c> updatedConversations = new Map<Id, LiveText__Conversation_Header__c>();

        for (LiveText__Conversation_Header__c conversation : conversations) {
            for (LiveText__SMS_Text__c message : messagesByConversationId.get(conversation.Id)) {
                if (this.updateConversationForMessage(message, conversation) && !updatedConversations.containsKey(conversation.Id)) {
                    updatedConversations.put(conversation.Id, conversation);
                }
            }
        }

        if (!updatedConversations.isEmpty()) {
            update updatedConversations.values();
        }
    }

    /**
     * Check if the message is assigned to a conversation and if it was not before.
     *
     * @param message
     * @param oldMessage
     *
     * @return
     */
    private Boolean isNewlyAssignedToConversation(LiveText__SMS_Text__c message, LiveText__SMS_Text__c oldMessage) {
        if (String.isBlank(message.LiveText__Conversation_Header__c)) {
            return false;
        }

        if (oldMessage != null && !String.isBlank(oldMessage.LiveText__Conversation_Header__c)) {
            return false;
        }

        return true;
    }

    /**
     * Dispatch the timestamp updates to the respective submethod regarding whether it's an in- or outbound message.
     *
     * @param message
     * @param conversation
     *
     * @return
     */
    private Boolean updateConversationForMessage(LiveText__SMS_Text__c message, LiveText__Conversation_Header__c conversation) {
        if (message.LiveText__Sent_To_Customer__c) {
            return this.updateConversationForOutboundMessage(message, conversation);
        }

        return this.updateConversationForInboundMessage(message, conversation);
    }

    /**
     * Update the LastMessageReceived timestamp and agent reply pending since timestamps, if the message is eligible.
     *
     * @param message
     * @param conversation
     *
     * @return
     */
    private Boolean updateConversationForInboundMessage(LiveText__SMS_Text__c message, LiveText__Conversation_Header__c conversation) {
        System.debug('Found inbound message');
        System.debug(message);

        if (message.LiveText__Source__c == 'LiveText') {
            /* it's an inbound message */
            conversation.LastMessageReceived__c = Datetime.now();

            if (conversation.AgentReplyPendingSince__c == null) {
                conversation.AgentReplyPendingSince__c = Datetime.now();
            }

            return true;
        }

        return false;
    }

    /**
     * Update the LastMessageSent timestamp and clear agent reply pending since timestamps, if the message is eligible.
     *
     * @param message
     * @param conversation
     *
     * @return
     */
    private Boolean updateConversationForOutboundMessage(LiveText__SMS_Text__c message, LiveText__Conversation_Header__c conversation) {
        System.debug('Found outbound message');
        System.debug(message);

        if (conversation.LiveText__Status__c == 'Active' && message.LiveText__Source__c == 'Salesforce' && !message.Is_Transfer_Message__c) {
            conversation.LastMessageSent__c = Datetime.now();
            conversation.AgentReplyPendingSince__c = null;

            return true;
        }

        return false;
    }
}