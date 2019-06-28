/*------------------------------------------------------------
    Author: Sven Kretschmann
    Company: Salesforce
    Description: Execute logic when closing cases.
    Inputs: n.a.
    Test Class: CaseCloseService_Test

    History
    <Date>		<Authors Name> 		<Brief Description of Change>
    25.01.2019	Sven Kretschmann    Initial creation with close logic
------------------------------------------------------------*/
public with sharing class CaseCloseService {

    /*------------------------------------------------------------
    Author:      Sven Kretschmann
    Company:     Salesforce
    Description: Update related data for these freshly closed cases
                 See MOS-245 for more information
    Inputs:      Map<Id, Case>
    Returns:     void
    Created:     25.01.2019
    ------------------------------------------------------------*/
    public void finishClosedCases(Map<Id, Case> closedCases) {
        /*
            This query assumes there won't be as much as 50k conversation on all the affected cases here.
            If this should become an issue, the logic has to be moved into a batch job.
        */
        final List<LiveText__Conversation_Header__c> conversations = [
            SELECT
                Id,
                Name,
                LiveText__Transcript_Summary_1__c,
                LiveText__Transcript_Summary_2__c,
                LiveText__Case__c
            FROM
                LiveText__Conversation_Header__c
            WHERE
                LiveText__Case__c IN :closedCases.keySet()
            ORDER BY
                SystemModstamp DESC
            LIMIT 50000
        ];

        final Set<Id> handledCasesIds = new Set<Id>();
        final List<LiveText__Conversation_Header__c> updatedConversations = new List<LiveText__Conversation_Header__c>();

        System.debug('Found ' + conversations.size() + ' conversations for these cases, identifying the latest ones for each.');

        for (LiveText__Conversation_Header__c conversation : conversations) {
            final Id caseId = conversation.LiveText__Case__c;

            if (handledCasesIds.contains(caseId)) {
                System.debug('Case ' + closedCases.get(caseId).CaseNumber + ' already has a conversation assigned, ignore conversation ' + conversation.Name);
                continue;
            }

            handledCasesIds.add(caseId);

            this.addCaseCloseMessage(closedCases.get(caseId), conversation);
            updatedConversations.add(conversation);
        }

        if (!updatedConversations.isEmpty()) {
            update updatedConversations;
        }
    }

    /*------------------------------------------------------------
    Author:      Sven Kretschmann
    Company:     Salesforce
    Description: Update the transcript of the conversation to include the case close message.
    Inputs:      Map<Id, Case>
    Returns:     void
    Created:     25.01.2019
    ------------------------------------------------------------*/
    private void addCaseCloseMessage(Case c, LiveText__Conversation_Header__c conversation) {
        System.debug('Adding a close message of case ' + c.CaseNumber + ' to conversation ' + conversation.Name);

        final String link = '<a href="/{0}"><i>{1}</i></a>';

        final String author = String.format(link, new List<String>{
            UserInfo.getUserId(),
            UserInfo.getName()
        });

        final String caseCaption = String.format(link, new List<String>{
            c.Id,
            c.CaseNumber
        });

        final String info = String.format(Label.Case_Close_TranscriptMessage, new List<String>{
            author,
            caseCaption,
            Datetime.now().format()
        });

        final String message = String.format('<p style="padding: 1% 0 1% 0; background: #eef; border-bottom: 1px solid #d8dde6;">&gt;&gt;&gt; {0} &lt;&lt;&lt;</p>', new List<String>{
            info
        });

        if (String.isBlank(conversation.LiveText__Transcript_Summary_1__c)) {
            /* no transcript, just insert the message */
            System.debug('No transcript yet, insert the message ' + message);
            conversation.LiveText__Transcript_Summary_1__c = message;
            return;
        }

        final Integer messageLength = message.length();
        final Integer transcript1Length = conversation.LiveText__Transcript_Summary_1__c.length();

        final Integer maxLength = LiveText__Conversation_Header__c.LiveText__Transcript_Summary_1__c.getDescribe().getLength();

        if (transcript1Length + messageLength <= maxLength) {
            /* the transcript 1 field has enough space for the message */
            System.debug('Only transcript 1 necessary, prepend the message ' + message + conversation.LiveText__Transcript_Summary_1__c);
            conversation.LiveText__Transcript_Summary_1__c = message + conversation.LiveText__Transcript_Summary_1__c;
            return;
        }

        /* we need to move some parts from the first to the second transcript field */
        final List<String> paragraphs = conversation.LiveText__Transcript_Summary_1__c.split('<p');

        if (paragraphs.size() == 1) {
            /* no paragraphs found, split by length */
            final String cutOver = conversation.LiveText__Transcript_Summary_1__c.substring(transcript1Length - messageLength);

            System.debug('No paragraph found, move by text length, prepend the message ' + message);

            conversation.LiveText__Transcript_Summary_2__c = this.prependString(cutOver, conversation.LiveText__Transcript_Summary_2__c, maxLength);
            conversation.LiveText__Transcript_Summary_1__c = message + conversation.LiveText__Transcript_Summary_1__c.substring(0, transcript1Length - messageLength);
            return;
        }

        /* move as many paragraphs as required to transcript 2 */
        System.debug('Move as many paragraphs from t1 to t2 as required.');

        for (Integer movedLength = 0; movedLength < messageLength;) {
            final String paragraph = paragraphs.remove(paragraphs.size() - 1);
            movedLength += paragraph.length();

            conversation.LiveText__Transcript_Summary_2__c = this.prependString('<p' + paragraph, conversation.LiveText__Transcript_Summary_2__c, maxLength);
            System.debug('Moved ' + '<p' + paragraph);
            System.debug(movedLength);
        }

        System.debug('Prepending message with remaining paragraphs ' + message + String.join(paragraphs, '<p'));
        conversation.LiveText__Transcript_Summary_1__c = message + String.join(paragraphs, '<p');
    }

    private String prependString(final String prefix, String data, final Integer maxLength) {
        data = prefix + (String.isBlank(data) ? '' : data);

        if (data.length() > maxLength) {
            /* truncate the end of the conversation summary, maybe not the best solution */
            data = data.substring(0, maxLength - 1) + '…';
        }

        return data;
    }
}