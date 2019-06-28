/*------------------------------------------------------------
Author:      Pavel Usoltsev
Company:     Salesforce
Description: A utility class for the Message live trigger
Inputs:      Triggered MessageLive objects
Test Class:  MessageLiveHandler_Test

History
7/22/18    Pavel Usoltsev    Initial Version
------------------------------------------------------------*/

public with sharing class MessageLiveHandler extends TriggerHandler {

    public MessageLiveHandler() {
        this.setMaxLoopCount(15);
    }

    protected override void afterInsert() {
        checkOneTypeLiveMessageActive();
    }

    protected override void beforeUpdate() {
        checkOneTypeLiveMessageActive();
    }

    /*------------------------------------------------------------
    Author:      Pavel Usoltsev
    Company:     Salesforce
    Description: Check that only one instance of the message lives can be active at the same time with one type
    Inputs:      List<MessageLive__c>
    Returns:     void
    Created:     7/22/18
    ------------------------------------------------------------*/
    private void checkOneTypeLiveMessageActive() {

        List<MessageLive__c> messages = [SELECT Id, Name, Active__c, RecordTypeId, LiveMessageNumber__c FROM MessageLive__c WHERE Active__c = true AND Id NOT IN:Trigger.new];
        System.debug('EXIST LIVE MESSAGES: ' + messages);

        if (!messages.isEmpty()) {
            for (MessageLive__c message : (List<MessageLive__c>) Trigger.new) {


                for (MessageLive__c existMessage : messages) {

                    if (message.LiveMessageNumber__c == existMessage.LiveMessageNumber__c && message.Active__c && existMessage.RecordTypeId == message.RecordTypeId && existMessage.Id != message.Id && existMessage.Active__c) {
                        message.addError('The message with this type already activated!');
                    }
                }
            }
        }

    }

}