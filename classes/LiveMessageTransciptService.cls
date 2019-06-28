/*------------------------------------------------------------
    Author: Pavel Kalinin
    Company: Salesforce
    Description: Logic to create a transcription for the livemessage session
    Inputs: n.a.
    Test Class: CaseCloseService_Test

    History
    <Date>		<Authors Name> 		<Brief Description of Change>
    04.03.2019	Pavel Kalinin    Initial creation
------------------------------------------------------------*/
global with sharing class LiveMessageTransciptService {

    private static final Integer MAX_LENGTH = LiveText__Conversation_Header__c.LiveText__Transcript_Summary_1__c.getDescribe().getLength();
    private List<LiveText__SMS_Text__c> smsTextsToDelete;

    global LiveMessageTransciptService() {
        this.smsTextsToDelete = new List<LiveText__SMS_Text__c>();
    }

    /*------------------------------------------------------------
    Author:      Pavel Kalininn
    Company:     Salesforce
    Description: Generate transcription for ended sessions
    Inputs:      LiveText__Conversation_Header__c session
    Returns:     LiveText__Conversation_Header__c
    Created:     04.03.2019
    ------------------------------------------------------------*/
    public LiveText__Conversation_Header__c generateTranscript(LiveText__Conversation_Header__c session) {
        if (session == null || session.LiveText__SMS_Text__r == null || session.LiveText__SMS_Text__r.isEmpty()) {
            return null;
        }
        session = updateTranscriptFields(session);
        smsTextsToDelete.addAll(session.LiveText__SMS_Text__r);
        return session;
    }

    /*------------------------------------------------------------
    Author:      Pavel Kalininn
    Company:     Salesforce
    Description: Generate transcription for ended sessions by it's Id
    Inputs:      LiveText__Conversation_Header__c session
    Returns:     LiveText__Conversation_Header__c
    Created:     04.03.2019
    ------------------------------------------------------------*/
    webservice static LiveText__Conversation_Header__c generateTranscriptForSessionId(String sessionId) {
        LiveText__Conversation_Header__c session = [
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
                Id = :sessionId
        ];

        if (session == null || session.LiveText__SMS_Text__r == null || session.LiveText__SMS_Text__r.isEmpty()) {
            return null;
        }

        session = updateTranscriptFields(session);
        delete session.LiveText__SMS_Text__r;

        return session;
    }

    /*------------------------------------------------------------
    Author:      Pavel Kalininn
    Company:     Salesforce
    Description: Populate transcription fields for ended session
    Inputs:      LiveText__Conversation_Header__c session
    Returns:     LiveText__Conversation_Header__c
    Created:     04.03.2019
    ------------------------------------------------------------*/
    public static LiveText__Conversation_Header__c updateTranscriptFields(LiveText__Conversation_Header__c session) {
        String transcriptMessageStart = '····LiveMessage Session Started: '
            + session.LiveText__SessionReopenedTime__c.format('EEEE, MMMM d')
            + 'th '
            + session.LiveText__SessionReopenedTime__c.format('yyyy')
            + ' at '
            + session.LiveText__SessionReopenedTime__c.format('hh:mm:ss aaa')
            +' ···· <br></br><br></br>';
        Integer transcript1Length = (String.isBlank(session.LiveText__Transcript_Summary_1__c)) ? 0 : session.LiveText__Transcript_Summary_1__c.length();
        Integer transcript2Length = (String.isBlank(session.LiveText__Transcript_Summary_2__c)) ? 0 : session.LiveText__Transcript_Summary_2__c.length();
        if (transcript1Length + transcriptMessageStart.length() < MAX_LENGTH) {
            if (String.isBlank(session.LiveText__Transcript_Summary_1__c)) {
                session.LiveText__Transcript_Summary_1__c = transcriptMessageStart;
            } else {
                session.LiveText__Transcript_Summary_1__c += '<br></br><br></br>' + transcriptMessageStart;
            }
        } else if (transcript2Length + transcriptMessageStart.length() < MAX_LENGTH) {
            if (String.isBlank(session.LiveText__Transcript_Summary_2__c)) {
                session.LiveText__Transcript_Summary_2__c = transcriptMessageStart;
            } else {
                session.LiveText__Transcript_Summary_2__c += '<br></br><br></br>' + transcriptMessageStart;
            }
        }

        for (LiveText__SMS_Text__c message : session.LiveText__SMS_Text__r) {
            String transcriptMessage = generateTranscriptMessage(session, message);

            transcript1Length = (String.isBlank(session.LiveText__Transcript_Summary_1__c)) ? 0 : session.LiveText__Transcript_Summary_1__c.length();
            transcript2Length = (String.isBlank(session.LiveText__Transcript_Summary_2__c)) ? 0 : session.LiveText__Transcript_Summary_2__c.length();

            if (transcript1Length + transcriptMessage.length() < MAX_LENGTH) {
                if (String.isBlank(session.LiveText__Transcript_Summary_1__c)) {
                    session.LiveText__Transcript_Summary_1__c = transcriptMessage;
                } else {
                    session.LiveText__Transcript_Summary_1__c += transcriptMessage;
                }
            } else if (transcript2Length + transcriptMessage.length() < MAX_LENGTH) {
                if (String.isBlank(session.LiveText__Transcript_Summary_2__c)) {
                    session.LiveText__Transcript_Summary_2__c = transcriptMessage;
                } else {
                    session.LiveText__Transcript_Summary_2__c += transcriptMessage;
                }
            }
        }

        String transcriptMessageEnd = '····LiveMessage Session Ended: '
            + Datetime.now().format('EEEE, MMMM d')
            + 'th '
            + Datetime.now().format('yyyy')
            + ' at '
            + Datetime.now().format('hh:mm:ss aaa')
            +' ····';
        transcript1Length = (String.isBlank(session.LiveText__Transcript_Summary_1__c)) ? 0 : session.LiveText__Transcript_Summary_1__c.length();
        transcript2Length = (String.isBlank(session.LiveText__Transcript_Summary_2__c)) ? 0 : session.LiveText__Transcript_Summary_2__c.length();
        if (transcript1Length + transcriptMessageEnd.length() < MAX_LENGTH) {
            session.LiveText__Transcript_Summary_1__c += transcriptMessageEnd;
        } else if (transcript2Length + transcriptMessageStart.length() < MAX_LENGTH) {
            session.LiveText__Transcript_Summary_2__c += transcriptMessageEnd;
        }

        return session;
    }

    /*------------------------------------------------------------
    Author:      Pavel Kalininn
    Company:     Salesforce
    Description: Generate transcription for a single message
    Inputs:      LiveText__Conversation_Header__c session
                 LiveText__SMS_Text__c message
    Returns:     String
    Created:     04.03.2019
    ------------------------------------------------------------*/
    public static String generateTranscriptMessage(LiveText__Conversation_Header__c session, LiveText__SMS_Text__c message) {
        String transcriptMessage;

        String author = '<b>'
            + ((message.LiveText__Sent_To_Customer__c == true) ? (message.Owner.Name) : (message.LiveText__First_Name__c + ' ' + message.LiveText__Last_Name__c))
            + ' ' + message.CreatedDate.format()
            + '</b>';

        transcriptMessage = author + '<br></br>' + message.LiveText__Message__c + '<br></br><br></br>';

        return transcriptMessage;
    }

    /*------------------------------------------------------------
    Author:      Pavel Kalininn
    Company:     Salesforce
    Description: Delete related sms text records for ended sessions
    Inputs:      List<LiveText__SMS_Text__c> smsTextsToDelete
    Returns:     void
    Created:     04.03.2019
    ------------------------------------------------------------*/
    public void deleteSMSTexts() {
        if (smsTextsToDelete != null && !smsTextsToDelete.isEmpty()) {
            delete smsTextsToDelete;
        }
    }
}