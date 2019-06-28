/**
 * Created by Pavel Usoltsev on 7/16/18.
 */

trigger TriggerLiveMessageSession on LiveText__Conversation_Header__c (before insert, before update, before delete, after insert, after update) {
    new LiveMessageSessionHandler().run();
}