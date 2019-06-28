/**
 * Created by Pavel Usoltsev on 7/12/18.
 */

trigger TriggerMessageLive on MessageLive__c (before insert, before update, before delete, after insert) {
    new MessageLiveHandler().run();

}