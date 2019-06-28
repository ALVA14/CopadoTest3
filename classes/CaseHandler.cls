/*------------------------------------------------------------
    Author: Sven Kretschmann
    Company: Salesforce
    Description: Domain handler for the Case object.
    Inputs: n.a.
    Test Class: CaseHandler_Test

    History
    <Date>		<Authors Name> 		<Brief Description of Change>
    25.01.2019	Sven Kretschmann    Initial creation with trigger logic
    21.02.2019  Pavel Kalinin       implemented MOS-448 (case reassignment validation)
------------------------------------------------------------*/
public with sharing class CaseHandler extends TriggerHandler {

    /**
     * Initialize this handler, prevent infinite recursion
     */
    public CaseHandler() {
        super();
        this.setMaxLoopCount(50);
    }

    /*------------------------------------------------------------
    Author:      Sven Kretschmann
    Company:     Salesforce
    Description: Execute logic after updating cases
    Inputs:      List<Case>
    Returns:     void
    Created:     25.01.2019
    ------------------------------------------------------------*/
    protected override void afterUpdate() {
        /* will hold the freshly closed cases */
        final Map<Id, Case> closedCases = new Map<Id, Case>();

        /* extract the respective lists for handling the changes */
        for (Case c : (List<Case>) Trigger.new) {
            Case oldCase = (Case) Trigger.oldMap.get(c.Id);

            if (c.IsClosed && !oldCase.IsClosed) {
                closedCases.put(c.Id, c);
            }
        }

        if (!closedCases.isEmpty()) {
            (new CaseCloseService()).finishClosedCases(closedCases);
        }
    }

    /*------------------------------------------------------------
    Author:      Pavel Kalinin
    Company:     Salesforce
    Description: Execute logic before updating cases
    Inputs:      List<Case>
    Returns:     void
    Created:     21.02.2019
    ------------------------------------------------------------*/
    protected override void beforeUpdate() {
        caseReassignmentValidation();
    }

    /*------------------------------------------------------------
    Author:      Pavel Kalinin
    Company:     Salesforce
    Description: validate if case is allowed to be reassigned:
                 1. case is reassigned by user with a custom permission (API name is Case_Reassignment)
                 2. case is reassigned by clicking on send message button (in that case a new owner has to have an active conversation)
    Inputs:      List<Case>
    Returns:     void
    Created:     21.02.2019
    ------------------------------------------------------------*/
    private void caseReassignmentValidation() {
        // 1. case is reassigned by user with a custom permission (API name is Case_Reassignment)
        if (FeatureManagement.checkPermission('Case_Reassignment')) {
            return;
        }

        Map<Id, LiveText__Conversation_Header__c> activeSessionsByCase = new Map<Id, LiveText__Conversation_Header__c>();
        for (LiveText__Conversation_Header__c session : [SELECT Id, OwnerId, LiveText__Case__c
                                                         FROM LiveText__Conversation_Header__c
                                                         WHERE LiveText__Case__c IN :Trigger.newMap.keySet()
                                                               AND LiveText__Status__c = 'Active']) {

            activeSessionsByCase.put(session.LiveText__Case__c, session);
        }

        for (Case currentCase : (List<Case>) Trigger.new) {
            Boolean ownerWasChanged = ((Case) Trigger.oldMap.get(currentCase.Id)).OwnerId != currentCase.OwnerId;
            Boolean newOwnerIsUser = currentCase.OwnerId.getSObjectType() == User.sObjectType;
            Boolean oldOwnerIsUser = ((Case) Trigger.oldMap.get(currentCase.Id)).OwnerId.getSObjectType() == User.sObjectType;
            Boolean newOwnerDontHaveActiveConversation = !activeSessionsByCase.containsKey(currentCase.Id)
                || activeSessionsByCase.get(currentCase.Id).OwnerId != currentCase.OwnerId;

            if (ownerWasChanged == true
                && newOwnerIsUser == true
                && oldOwnerIsUser == true
                && newOwnerDontHaveActiveConversation == true) {

                currentCase.addError(Label.Case_Reassignment_ErrorMsg);
            }
        }
    }

}