/*------------------------------------------------------------
Author:      Pavel Usoltsev
Company:     Salesforce
Description: A utility class for the Option trigger
Inputs:      Triggered option objects
Test Class:  OptionHandler_Test

History
7/26/18   Pavel Usoltsev    Initial Version
------------------------------------------------------------*/

public with sharing class OptionHandler extends TriggerHandler {

    public OptionHandler() {
        this.setMaxLoopCount(10);
    }

    protected override void beforeInsert() {
        checkIfOptionNumberIsAssigned();
    }

    protected override void beforeUpdate() {
        checkIfOptionNumberIsAssigned();
    }

    /*------------------------------------------------------------
    Author:      Pavel Usoltsev
    Company:     Salesforce
    Description: Check that the options must have unique number for the message live object
    Inputs:      List<Option__c>
    Returns:     void
    Created:     7/26/18
    ------------------------------------------------------------*/
    private void checkIfOptionNumberIsAssigned() {

        Map<Id, List<Option__c>> messageOptions = getOptionsByMessageLive();

        for (Option__c option : (List<Option__c>) Trigger.new) {
            if (messageOptions.containsKey(option.MessageLive__c)) {
                for (Option__c optionExist : messageOptions.get(option.MessageLive__c)) {
                    if (option.Option_No__c == optionExist.Option_No__c && option.Id != optionExist.Id) {
                        option.addError('The option with this number already exist!');
                    }
                }
            }
        }

    }

    /*------------------------------------------------------------
    Author:      Pavel Usoltsev
    Company:     Salesforce
    Description: Get options map by their message live
    Inputs:      List<Option__c>
    Returns:     Map options by message live
    Created:     7/27/18
    ------------------------------------------------------------*/
    private Map<Id, List<Option__c>> getOptionsByMessageLive() {

        List<Option__c> options = [SELECT Id, Name, Option_No__c, MessageLive__c FROM Option__c ORDER BY Option_No__c ASC];

        Map<Id, List<Option__c>> messageOptions = new Map<Id, List<Option__c>>();

        for (Option__c option : options) {

            if (messageOptions.containsKey(option.MessageLive__c)) {
                messageOptions.get(option.MessageLive__c).add(option);
            } else {
                List<Option__c> newOptions = new List<Option__c>();
                newOptions.add(option);
                messageOptions.put(option.MessageLive__c, newOptions);
            }
        }

        return messageOptions;
    }

}