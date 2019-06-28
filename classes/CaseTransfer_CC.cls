/*------------------------------------------------------------
Author:      Pavel Kalinin
Company:     Salesforce
Description: A controller class for CaseTransfer page to provide functionality for case transfering
Inputs:      stdController - Case standard controller
Test Class:  CaseTransfer_CC_Test

History
1/08/19      Pavel Kalinin    Initial version
1/23/19      Pavel Kalinin    fix of MOS-246
2/11/19      Pavel Kalinin    fix of MOS-380
2/12/19      Pavel Kalinin    fix of MOS-373
------------------------------------------------------------*/
public class CaseTransfer_CC {

    public Case currentCase { get; private set; } //to store the cussrent case
    public List<SelectOption> availableQueues { get; private set; } //list of queues available for transfer
    public String selectedQueue { get; set; } //id of selected queue
    public String comment { get; set; } //comment text, entered by user
    public Boolean isTransferred { get; private set; } //flag that reflects the status of the transfer - true if case is transferred to a queue

    public CaseTransfer_CC(ApexPages.StandardController stdController) {
        /* single line to not reduce coverage, sadly it won't work in unit tests */
        if (!Test.isRunningTest()) { stdController.addFields(new List<String>{ 'Status', 'OwnerId', 'IsClosed' }); }

        this.currentCase = (Case)stdController.getRecord();
        this.isTransferred = false;

        this.availableQueues = new List<SelectOption>();
        for (Group queue : [SELECT Id, Name FROM Group WHERE Type = 'Queue']) {
            this.availableQueues.add(new SelectOption(queue.Id, queue.Name));
        }

        if (this.currentCase.IsClosed) {
            ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, Label.Case_Transfer_Exception_ClosedCase));
        }
    }

    /*------------------------------------------------------------
    Author:      Pavel Kalinin
    Company:     Salesforce
    Description: method to transfer case - creates case comment, changes case's status to 'Waiting for Transfer' and assign it to selected queue

    Inputs:      none
    Returns:     PageReference
    Created:     1/08/19
    ------------------------------------------------------------*/
    public PageReference transfer() {
        if (currentCase == null || String.isBlank(selectedQueue) || String.isBlank(comment)) {
            ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.WARNING, Label.Case_Transfer_Exception_MissingData));
            return null;
        }

        LiveText__Conversation_Header__c session = this.findCurrentConversation();

        if (session == null) {
            ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.WARNING, Label.Case_Transfer_Exception_MissingSession));
            return null;
        }

        CaseComment cc = new CaseComment(
            ParentId = currentCase.Id,
            CommentBody = comment
        );

        insert cc;

        Group queue = [SELECT Id, Name, DeveloperName FROM Group WHERE Type = 'Queue' AND Id = :selectedQueue];

        currentCase.Status = 'Waiting for Transfer';
        currentCase.OwnerId = selectedQueue;
        currentCase.ResponsibleAgencyId__c = selectedQueue;
        currentCase.ResponsibleAgency__c = queue.Name;

        update currentCase;

        session.Transferred__c = true;
        session.LiveText__Status__c = 'Ended';
        session.Transfer_To_Queue__c = selectedQueue;
        session.ResponsibleAgencyId__c = selectedQueue;
        session.ResponsibleAgency__c = queue.Name;
        session.LiveText__MessagePreview__c = Label.Case_Transfer_Transfer_Mark + ' - ' + comment;

        System.debug('updating conversation for transfer');
        System.debug(session);
        update session;

        isTransferred = true;
        return null;
    }

    /*------------------------------------------------------------
    Author:      Sven Kretschmann
    Company:     Salesforce
    Description: Find the current conversation lead by the running user for this case.

    Inputs:      none
    Returns:     LiveText__Conversation_Header__c
    Created:     30.01.2019
    ------------------------------------------------------------*/
    private LiveText__Conversation_Header__c findCurrentConversation() {
        /*
           First try the youngest active one, if that's not available (e.g. the agent has ended the session before),
           we take any conversation from the case and agent
         */
        List<LiveText__Conversation_Header__c> sessions = [
            SELECT Id, Transfer_To_Queue__c, LiveText__Support_Number__c, LiveText__Support_Number__r.LiveText__Number__c
            FROM LiveText__Conversation_Header__c
            WHERE LiveText__Case__c = :currentCase.Id AND LiveText__Status__c = 'Active' AND OwnerId = :UserInfo.getUserId()
            ORDER BY CreatedDate DESC
        ];

        if (!sessions.isEmpty()) {
            return sessions[0];
        }

        sessions = [
            SELECT Id, Transfer_To_Queue__c, LiveText__Support_Number__c, LiveText__Support_Number__r.LiveText__Number__c
            FROM LiveText__Conversation_Header__c
            WHERE LiveText__Case__c = :currentCase.Id AND OwnerId = :UserInfo.getUserId()
            ORDER BY CreatedDate DESC
        ];

        return !sessions.isEmpty() ? sessions[0] : null;
    }

}