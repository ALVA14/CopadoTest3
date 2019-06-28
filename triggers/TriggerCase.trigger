/**
 * @author Sven Kretschmann <skretschmann@salesforce.com>
 */
trigger TriggerCase on Case (before insert, before update, before delete, after insert, after update, after delete, after undelete) {
    (new CaseHandler()).run();
}