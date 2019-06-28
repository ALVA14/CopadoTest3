/**
 * Created by skarmakar on 7/2/18.
 */

trigger TriggerSMSText on LiveText__SMS_Text__c (after insert, before insert, after update, before update, before delete, after delete) {
    new SMSTextHandler().run();
}