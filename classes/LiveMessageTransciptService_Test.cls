/*------------------------------------------------------------------------
Author:      Pavel Kalinin
Company:     Salesforce
Description: A test class created to validate class LiveMessageTransciptService
             Tests executed:
             1 - testGenerateTranscript()
             test of generation transcript for ended session
             2 - testGenerateTranscriptForSessionId()
             test of generation transcript for ended session by it's id
History
04.03.2019     Pavel Kalinin    Initial Version
28.03.2019  Stefano Pramparo    Added new method to verify correct order of Sms to fix INC0306657
----------------------------------------------------------------------------*/
@isTest
private class LiveMessageTransciptService_Test {

    @isTest static void testGenerateTranscript() {
        TestDataFactory.setInsertOBjects(true);

        //LiveText__Conversation_Header__c
        TestDataFactory.setFieldNameValuePairs('LiveText__Status__c', 'Ended');
        TestDataFactory.setFieldNameValuePairs('LiveText__Transcript_Summary_1__c', null);
        LiveText__Conversation_Header__c session = (LiveText__Conversation_Header__c) TestDataFactory.createSObject('LiveText__Conversation_Header__c');
        TestDataFactory.resetFieldNameValuePairs();

        //LiveText__SMS_Text__c
        TestDataFactory.setFieldNameValuePairs('LiveText__Conversation_Header__c', session.Id);
        TestDataFactory.setFieldNameValuePairs('LiveText__First_Name__c', 'Tony');
        TestDataFactory.setFieldNameValuePairs('LiveText__Last_Name__c', 'Stark');
        TestDataFactory.setFieldNameValuePairs('LiveText__Originating_Number__c', 'test');
        TestDataFactory.setFieldNameValuePairs('LiveText__Message__c', 'hello');
        TestDataFactory.setFieldNameValuePairs('LiveText__Status__c', '');
        LiveText__SMS_Text__c smsTextData = (LiveText__SMS_Text__c) TestDataFactory.createSObject('LiveText__SMS_Text__c');
        TestDataFactory.resetFieldNameValuePairs();

        System.assertEquals(1, [SELECT Id FROM LiveText__SMS_Text__c WHERE LiveText__Conversation_Header__c = :session.Id].size());

        LiveText__Conversation_Header__c lmSession = [
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
                        LiveText__EndedTime__c, (
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
                        Id = :session.Id
        ];
        System.assertEquals(null, lmSession.LiveText__Transcript_Summary_1__c);

        Test.startTest();
        LiveMessageTransciptService lmts = new LiveMessageTransciptService();
        lmSession = lmts.generateTranscript(lmSession);
        System.assertNotEquals(null, lmSession.LiveText__Transcript_Summary_1__c);
        lmts.deleteSMSTexts();
        Test.stopTest();

        System.assertEquals(0, [SELECT Id FROM LiveText__SMS_Text__c WHERE LiveText__Conversation_Header__c = :lmSession.Id].size());
    }

    @isTest static void testGenerateTranscriptForSessionId() {
        TestDataFactory.setInsertOBjects(true);

        //LiveText__Conversation_Header__c
        TestDataFactory.setFieldNameValuePairs('LiveText__Status__c', 'Ended');
        TestDataFactory.setFieldNameValuePairs('LiveText__Transcript_Summary_1__c', null);
        LiveText__Conversation_Header__c session = (LiveText__Conversation_Header__c) TestDataFactory.createSObject('LiveText__Conversation_Header__c');
        TestDataFactory.resetFieldNameValuePairs();

        //LiveText__SMS_Text__c
        TestDataFactory.setFieldNameValuePairs('LiveText__Conversation_Header__c', session.Id);
        TestDataFactory.setFieldNameValuePairs('LiveText__First_Name__c', 'Tony');
        TestDataFactory.setFieldNameValuePairs('LiveText__Last_Name__c', 'Stark');
        TestDataFactory.setFieldNameValuePairs('LiveText__Originating_Number__c', 'test');
        TestDataFactory.setFieldNameValuePairs('LiveText__Message__c', 'hello');
        TestDataFactory.setFieldNameValuePairs('LiveText__Status__c', '');
        LiveText__SMS_Text__c smsTextData = (LiveText__SMS_Text__c) TestDataFactory.createSObject('LiveText__SMS_Text__c');
        TestDataFactory.resetFieldNameValuePairs();

        System.assertEquals(1, [SELECT Id FROM LiveText__SMS_Text__c WHERE LiveText__Conversation_Header__c = :session.Id].size());

        Test.startTest();
        LiveText__Conversation_Header__c lmSession = LiveMessageTransciptService.generateTranscriptForSessionId(session.Id);
        System.assertNotEquals(null, lmSession.LiveText__Transcript_Summary_1__c);
        Test.stopTest();

        System.assertEquals(0, [SELECT Id FROM LiveText__SMS_Text__c WHERE LiveText__Conversation_Header__c = :session.Id].size());
    }
    @isTest
    static void testGenerateTranscriptMultipleSMSForSessionId() {

        TestDataFactory.setInsertOBjects(true);

        //disable trigger counter just for test
        TriggerHandler.bypass('TriggerSMSText');
        TriggerHandler.bypass('SMSTextHandler');

        //conversation to test transcript
        LiveText__Conversation_Header__c session = getSession();

        LiveText__Conversation_Header__c anotherSession = getSession();

        //first sms for session
        LiveText__SMS_Text__c smsTextData = getSms(session, 'hello');
        smsTextData = [select LiveText__Message__c,CreatedDate from LiveText__SMS_Text__c where Id = :smsTextData.Id];
        Test.setCreatedDate ( smsTextData.Id,DateTime.newInstance(2019,04,01,01,01,01));


        //2nd sms for session
        LiveText__SMS_Text__c secondSmsTextData = getSms(session, 'ciao');
        secondSmsTextData = [select LiveText__Message__c,CreatedDate from LiveText__SMS_Text__c where Id = :secondSmsTextData.Id];
        Test.setCreatedDate ( secondSmsTextData.Id,DateTime.newInstance(2019,04,01,01,01,02));

        Test.startTest();
        System.assertEquals(2, [SELECT Id FROM LiveText__SMS_Text__c WHERE LiveText__Conversation_Header__c = :session.Id].size());
        String transcript = '····LiveMessage Session Started: '
                + session.LiveText__SessionReopenedTime__c.format('EEEE, MMMM d')
                + 'th '
                + session.LiveText__SessionReopenedTime__c.format('yyyy')
                + ' at '
                + session.LiveText__SessionReopenedTime__c.format('hh:mm:ss aaa')
                + ' ···· <br></br><br></br>';
        transcript += '<b>Tony Stark ' + smsTextData.CreatedDate.format() + '</b><br></br>';
        transcript += secondSmsTextData.LiveText__Message__c + '<br></br><br></br>';
        transcript += '<b>Tony Stark ' + secondSmsTextData.CreatedDate.format() + '</b><br></br>';
        transcript += smsTextData.LiveText__Message__c + '<br></br><br></br>';
        transcript += '····LiveMessage Session Ended: '
                + Datetime.now().format('EEEE, MMMM d')
                + 'th '
                + Datetime.now().format('yyyy')
                + ' at '
                + Datetime.now().format('hh:mm:ss aaa')
                + ' ····';
        LiveText__Conversation_Header__c lmSession = LiveMessageTransciptService.generateTranscriptForSessionId(session.Id);

        System.assertNotEquals(transcript, lmSession.LiveText__Transcript_Summary_1__c);
        Test.stopTest();
    }
    private static void generateMassiveSms(Integer numSms, LiveText__Conversation_Header__c session) {
        List<LiveText__SMS_Text__c> listSms = new List<LiveText__SMS_Text__c>();
        for (Integer i = 0; i < numSms; i++) {
            LiveText__SMS_Text__c sms = new LiveText__SMS_Text__c(
                    LiveText__Conversation_Header__c = session.Id,
                    LiveText__First_Name__c = 'Tony',
                    LiveText__Last_Name__c = 'Stark',
                    LiveText__Originating_Number__c = 'test2',
                    LiveText__Message__c = 'sms ' + i,
                    LiveText__Status__c = '');
            listSms.add(sms);
        }
        insert listSms;
    }
    private static LiveText__SMS_Text__c getSms(LiveText__Conversation_Header__c session, String message) {
        TestDataFactory.setFieldNameValuePairs('LiveText__Conversation_Header__c', session.Id);
        TestDataFactory.setFieldNameValuePairs('LiveText__First_Name__c', 'Tony');
        TestDataFactory.setFieldNameValuePairs('LiveText__Last_Name__c', 'Stark');
        TestDataFactory.setFieldNameValuePairs('LiveText__Originating_Number__c', 'test');
        TestDataFactory.setFieldNameValuePairs('LiveText__Message__c', message);
        TestDataFactory.setFieldNameValuePairs('LiveText__Status__c', '');
        LiveText__SMS_Text__c smsTextData = (LiveText__SMS_Text__c) TestDataFactory.createSObject('LiveText__SMS_Text__c');
        TestDataFactory.resetFieldNameValuePairs();
        return smsTextData;
    }

    private static LiveText__Conversation_Header__c getSession() {
        TestDataFactory.setFieldNameValuePairs('LiveText__Status__c', 'Ended');
        TestDataFactory.setFieldNameValuePairs('LiveText__Transcript_Summary_1__c', null);
        LiveText__Conversation_Header__c session = (LiveText__Conversation_Header__c) TestDataFactory.createSObject('LiveText__Conversation_Header__c');
        TestDataFactory.resetFieldNameValuePairs();
        return session;
    }
}