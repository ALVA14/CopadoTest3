/*------------------------------------------------------------
Author:      Sven Kretschmann
Company:     Salesforce
Description: Handle all orphaned conversations (active at an offline user)
Inputs:      All active conversations
Test Class:  OrphanedConversationBatch_Test

History
15.02.2019   Sven Kretschmann   Initial Version
------------------------------------------------------------*/
public with sharing class OrphanedConversationBatch implements Database.Batchable<LiveText__Conversation_Header__c>, Database.Stateful, Schedulable {

    private LiveMessageTransciptService liveMessageTransciptService;

    /*------------------------------------------------------------
    Author:      Sven Kretschmann
    Company:     Salesforce
    Description: Scheduled execution of this job
    Inputs:      - schedulable context

    History
    15.02.2019   Sven Kretschmann   Initial Version
    ------------------------------------------------------------*/
    public void execute(SchedulableContext context) {
        Database.executeBatch(this);
    }

    /*------------------------------------------------------------
    Author:      Sven Kretschmann
    Company:     Salesforce
    Description: Find the active conversations owned by offline (Omni-Channel) users
    Inputs:      - batch context

    History
    15.02.2019   Sven Kretschmann   Initial Version
    ------------------------------------------------------------*/
    public List<LiveText__Conversation_Header__c> start(Database.BatchableContext context) {
        liveMessageTransciptService = new LiveMessageTransciptService();

        return [
            SELECT
                Id,
                OwnerId,
                ResponsibleAgencyId__c,
                LiveText__AcceptedBy__c,
                LastMessageSent__c,
                LastMessageReceived__c,
                LogoutAgentId__c,
                Logout__c,
                LiveText__Transcript_Summary_1__c,
                LiveText__Transcript_Summary_2__c,
                LiveText__Account__c,
                LiveText__SessionReopenedTime__c,
                LiveText__EndedTime__c,
                (
                    SELECT
                        Id,
                        LiveText__Sent_To_Customer__c,
                        LiveText__Message__c,
                        CreatedDate,
                        LiveText__First_Name__c,
                        LiveText__Last_Name__c,
                        OwnerId,
                        Owner.Name
                    FROM
                        LiveText__SMS_Text__r
                )
            FROM
                LiveText__Conversation_Header__c
            WHERE
            LiveText__Status__c = 'Active'
            AND
            OwnerId NOT IN (SELECT UserId FROM UserServicePresence WHERE IsCurrentState = TRUE)
        ];
    }

    /*------------------------------------------------------------
    Author:      Sven Kretschmann
    Company:     Salesforce
    Description: Execute the logic for the found conversations
    Inputs:      - batch context
                 - active conversations

    History
    15.02.2019   Sven Kretschmann   Initial Version
    ------------------------------------------------------------*/
    public void execute(Database.BatchableContext context, List<LiveText__Conversation_Header__c> conversations) {
        for (LiveText__Conversation_Header__c conversation : conversations) {
            if (conversation.LastMessageSent__c == null || conversation.LastMessageSent__c < conversation.LastMessageReceived__c) {
                System.debug('Customer is waiting for reply');
                System.debug(conversation);

                /* customer is waiting for reply */
                conversation.LogoutAgentId__c = conversation.OwnerId;
                conversation.Logout__c = true;
                conversation.LiveText__Status__c = 'New';
                if (!String.isBlank(conversation.ResponsibleAgencyId__c)) {
                    /* the LiveMessageSessionHandler should take care of properly routing the conversation anyway */
                    conversation.OwnerId = conversation.ResponsibleAgencyId__c;
                }
                conversation.LiveText__AcceptedBy__c = null;
            } else {
                System.debug('Conversation is waiting for customer');
                System.debug(conversation);

                /* agent was waiting for reply, but is now offline */
                conversation.LiveText__Status__c = 'Ended';
                conversation.Logout__c = false;
                conversation.LogoutAgentId__c = conversation.OwnerId;

                liveMessageTransciptService.generateTranscript(conversation);
            }
        }

        System.debug('Updating conversations');
        System.debug(conversations);
        update conversations;
    }

    /*------------------------------------------------------------
    Author:      Sven Kretschmann
    Company:     Salesforce
    Description: Clean up the mess. Just kidding, nothing to do here.
    Inputs:      - batch context

    History
    15.02.2019   Sven Kretschmann   Initial Version
    ------------------------------------------------------------*/
    public void finish(Database.BatchableContext context) {
        liveMessageTransciptService.deleteSMSTexts();
    }
}