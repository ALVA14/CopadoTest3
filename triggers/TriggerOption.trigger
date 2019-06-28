/**
 * Created by Pavel Usoltsev on 7/12/18.
 */

trigger TriggerOption on Option__c (after insert, before insert, after update, before update, before delete, after delete) {
    new OptionHandler().run();
}