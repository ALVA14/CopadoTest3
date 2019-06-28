/*------------------------------------------------------------
    Author: Sven Kretschmann
    Company: Salesforce
    Description: Test class for the CaseCloseService.
                 Tests executed:
                 1 - testFinishClosedCasesWithNoConversation()
                 (Made up use case) Close a case with no conversation
                 2 - testFinishClosedCasesWithNoTranscript()
                 (Made up use case) Close a case with a conversation without transcript
                 3 - testFinishClosedCasesWithSmallTranscript()
                 Close a case with a conversation with a small transcript
                 4 - testFinishClosedCasesWithLargeTranscript()
                 Close a case with a conversation with a large transcript (using both fields)
                 5 - testFinishClosedCasesWithLargeUnexpectedTranscript()
                 Close a case with a conversation with a large transcript (using both fields) not having paragraphs
                 6 - testFinishClosedCasesWithMultipleConversations()
                 Close a case with multiple conversations

    History
    <Date>		<Authors Name> 		<Brief Description of Change>
    25.01.2019	Sven Kretschmann    Initial creation with tests
------------------------------------------------------------*/
@IsTest
public with sharing class CaseCloseService_Test {

    @TestSetup
    public static void setupTestData() {
        TestDataFactory.setInsertOBjects(true);

        //LiveMessage Channel
        TestDataFactory.setFieldNameValuePairs('Name', 'testChannel');
        LiveText__LiveText_Number__c channel = (LiveText__LiveText_Number__c) TestDataFactory.createSObject('LiveText__LiveText_Number__c');
        TestDataFactory.resetFieldNameValuePairs();

        //Account
        TestDataFactory.setFieldNameValuePairs('RecordTypeId', 'LiveMessage');
        TestDataFactory.setFieldNameValuePairs('FirstName', 'Cooper');
        TestDataFactory.setFieldNameValuePairs('LastName', 'Hawkes');
        TestDataFactory.setFieldNameValuePairs('Phone', '+4917620944202');
        TestDataFactory.setFieldNameValuePairs('FacebookId__pc', '2157762154239024');
        TestDataFactory.setFieldNameValuePairs('CustomerId__pc', '1234567890');
        TestDataFactory.createSObject('Account');
        TestDataFactory.resetFieldNameValuePairs();

        Account testAccount = [SELECT Id, PersonContactId FROM Account];

        //Case
        TestDataFactory.setFieldNameValuePairs('RecordTypeId', 'LiveMessage');
        TestDataFactory.setFieldNameValuePairs('ContactId', testAccount.PersonContactId);
        TestDataFactory.setFieldNameValuePairs('AccountId', testAccount.Id);
        TestDataFactory.setFieldNameValuePairs('Status', 'Open');
        TestDataFactory.setFieldNameValuePairs('UsedLiveMessageNo__c', channel.Id);
        TestDataFactory.createSObject('Case');
        TestDataFactory.resetFieldNameValuePairs();
    }

    @IsTest
    public static void testFinishClosedCasesWithNoConversation() {
        Case testCase = [SELECT Id, RecordTypeId, ContactId, Status, AccountId, Contact.CustomerId__c FROM Case];

        Test.startTest();

        CaseCloseService service = new CaseCloseService();
        service.finishClosedCases(new Map<Id, Case>{
            testCase.Id => testCase
        });

        Test.stopTest();

        List<LiveText__Conversation_Header__c> conversations = [SELECT Id, LiveText__Transcript_Summary_1__c FROM LiveText__Conversation_Header__c];
        System.assertEquals(0, conversations.size());
    }

    @IsTest
    public static void testFinishClosedCasesWithNoTranscript() {
        Case testCase = [SELECT Id, CaseNumber, RecordTypeId, ContactId, Status, AccountId, Contact.CustomerId__c FROM Case];

        setupConversation(null);

        Test.startTest();

        CaseCloseService service = new CaseCloseService();
        service.finishClosedCases(new Map<Id, Case>{
            testCase.Id => testCase
        });

        Test.stopTest();

        List<LiveText__Conversation_Header__c> conversations = [SELECT Id, LiveText__Transcript_Summary_1__c, LiveText__Transcript_Summary_2__c FROM LiveText__Conversation_Header__c];
        System.assertEquals(1, conversations.size());
        System.assert(!String.isBlank(conversations[0].LiveText__Transcript_Summary_1__c));
        System.assert(conversations[0].LiveText__Transcript_Summary_1__c.contains('href="/' + UserInfo.getUserId() + '"'), 'Expected the transcript to contain a link to the running user');
        System.assert(conversations[0].LiveText__Transcript_Summary_1__c.contains(UserInfo.getName()), 'Expected the transcript to contain the name of the running user');
        System.assert(conversations[0].LiveText__Transcript_Summary_1__c.contains('href="/' + testCase.Id + '"'), 'Expected the transcript to contain a link to the test case');
        System.assert(conversations[0].LiveText__Transcript_Summary_1__c.contains(testCase.CaseNumber), 'Expected the transcript to contain the test case number');

        System.assert(String.isBlank(conversations[0].LiveText__Transcript_Summary_2__c));
    }

    @IsTest
    public static void testFinishClosedCasesWithSmallTranscript() {
        Case testCase = [SELECT Id, CaseNumber, RecordTypeId, ContactId, Status, AccountId, Contact.CustomerId__c FROM Case];

        setupConversation('<p>Some existing messages</p>');

        Test.startTest();

        CaseCloseService service = new CaseCloseService();
        service.finishClosedCases(new Map<Id, Case>{
            testCase.Id => testCase
        });

        Test.stopTest();

        List<LiveText__Conversation_Header__c> conversations = [SELECT Id, LiveText__Transcript_Summary_1__c, LiveText__Transcript_Summary_2__c FROM LiveText__Conversation_Header__c];
        System.assertEquals(1, conversations.size());
        System.assert(!String.isBlank(conversations[0].LiveText__Transcript_Summary_1__c));
        System.assert(conversations[0].LiveText__Transcript_Summary_1__c.endsWith('<p>Some existing messages</p>'));
        System.assert(conversations[0].LiveText__Transcript_Summary_1__c.contains('href="/' + UserInfo.getUserId() + '"'), 'Expected the transcript to contain a link to the running user');
        System.assert(conversations[0].LiveText__Transcript_Summary_1__c.contains(UserInfo.getName()), 'Expected the transcript to contain the name of the running user');
        System.assert(conversations[0].LiveText__Transcript_Summary_1__c.contains('href="/' + testCase.Id + '"'), 'Expected the transcript to contain a link to the test case');
        System.assert(conversations[0].LiveText__Transcript_Summary_1__c.contains(testCase.CaseNumber), 'Expected the transcript to contain the test case number');

        System.assert(String.isBlank(conversations[0].LiveText__Transcript_Summary_2__c));
    }

    @IsTest
    public static void testFinishClosedCasesWithLargeTranscript() {
        Case testCase = [SELECT Id, CaseNumber, RecordTypeId, ContactId, Status, AccountId, Contact.CustomerId__c FROM Case];

        Integer maxLength = LiveText__Conversation_Header__c.LiveText__Transcript_Summary_1__c.getDescribe().getLength();
        String transcript1 = '<p>' + TestDataFactory.getRandomString(maxLength - 7) + '</p>';
        setupConversation(transcript1, '<p>Some existing messages part 2</p>');

        Test.startTest();

        CaseCloseService service = new CaseCloseService();
        service.finishClosedCases(new Map<Id, Case>{
            testCase.Id => testCase
        });

        Test.stopTest();

        List<LiveText__Conversation_Header__c> conversations = [SELECT Id, LiveText__Transcript_Summary_1__c, LiveText__Transcript_Summary_2__c FROM LiveText__Conversation_Header__c];

        System.assertEquals(1, conversations.size());

        System.assert(!String.isBlank(conversations[0].LiveText__Transcript_Summary_1__c));
        System.assert(conversations[0].LiveText__Transcript_Summary_1__c.contains('href="/' + UserInfo.getUserId() + '"'), 'Expected the transcript to contain a link to the running user');
        System.assert(conversations[0].LiveText__Transcript_Summary_1__c.contains(UserInfo.getName()), 'Expected the transcript to contain the name of the running user');
        System.assert(conversations[0].LiveText__Transcript_Summary_1__c.contains('href="/' + testCase.Id + '"'), 'Expected the transcript to contain a link to the test case');
        System.assert(conversations[0].LiveText__Transcript_Summary_1__c.contains(testCase.CaseNumber), 'Expected the transcript to contain the test case number');

        /*
            we expect the complete transcript 1 to have been moved to transcript 2,
            leaving no space for the original transcript 2, and thus truncating the transcript
         */
        System.assertEquals(transcript1.substring(0, maxLength - 1) + '…', conversations[0].LiveText__Transcript_Summary_2__c);
    }

    @IsTest
    public static void testFinishClosedCasesWithLargeUnexpectedTranscript() {
        Case testCase = [SELECT Id, CaseNumber, RecordTypeId, ContactId, Status, AccountId, Contact.CustomerId__c FROM Case];

        Integer maxLength = LiveText__Conversation_Header__c.LiveText__Transcript_Summary_1__c.getDescribe().getLength();
        String transcript1 = TestDataFactory.getRandomString(maxLength);
        String transcript2 = 'Some existing messages part 2';

        setupConversation(transcript1, transcript2);

        Test.startTest();

        CaseCloseService service = new CaseCloseService();
        service.finishClosedCases(new Map<Id, Case>{
            testCase.Id => testCase
        });

        Test.stopTest();

        List<LiveText__Conversation_Header__c> conversations = [SELECT Id, LiveText__Transcript_Summary_1__c, LiveText__Transcript_Summary_2__c FROM LiveText__Conversation_Header__c];

        System.assertEquals(1, conversations.size());

        System.assert(!String.isBlank(conversations[0].LiveText__Transcript_Summary_1__c));
        System.assertEquals(maxLength, conversations[0].LiveText__Transcript_Summary_1__c.length());
        System.assert(conversations[0].LiveText__Transcript_Summary_1__c.contains('href="/' + UserInfo.getUserId() + '"'), 'Expected the transcript to contain a link to the running user');
        System.assert(conversations[0].LiveText__Transcript_Summary_1__c.contains(UserInfo.getName()), 'Expected the transcript to contain the name of the running user');
        System.assert(conversations[0].LiveText__Transcript_Summary_1__c.contains('href="/' + testCase.Id + '"'), 'Expected the transcript to contain a link to the test case');
        System.assert(conversations[0].LiveText__Transcript_Summary_1__c.contains(testCase.CaseNumber), 'Expected the transcript to contain the test case number');

        String movedCharacters = conversations[0].LiveText__Transcript_Summary_2__c.removeEnd(transcript2);
        String transcript1Remainder = transcript1.removeEnd(movedCharacters);

        /*
         * The following assertions explained (field name package has been shorted to LT__ for easier reading):
         * 1. We expect LT__Transcript_Summary_2__c to end with transcript2, which means the original content is still there
         * 2. We expect the start of LT__Transcript_Summary_2__c to be the end of transcript1
         * 3. We expect LT__Transcript_Summary_1__c to end with what has not been moved to 2
         * 4. We expect LT__Transcript_Summary_1__c to contain the maximum number of characters
         */
        System.assert(conversations[0].LiveText__Transcript_Summary_2__c.endsWith(transcript2));
        System.assert(transcript1.endsWith(movedCharacters));
        System.assert(conversations[0].LiveText__Transcript_Summary_1__c.endsWith(transcript1Remainder));
        System.assertEquals(maxLength, conversations[0].LiveText__Transcript_Summary_1__c.length());
    }

    @IsTest
    public static void testFinishClosedCasesWithMultipleConversations() {
        Case testCase = [SELECT Id, CaseNumber, RecordTypeId, ContactId, Status, AccountId, Contact.CustomerId__c FROM Case];

        setupConversation('<p>Some old messages</p>');

        /* idle for a second to allow proper sorting of the conversations */
        Datetime start = Datetime.now();

        while (start.second() == Datetime.now().second()) {
            /* noop */
        }

        setupConversation('<p>Some newer messages</p>');

        Test.startTest();

        CaseCloseService service = new CaseCloseService();
        service.finishClosedCases(new Map<Id, Case>{
            testCase.Id => testCase
        });

        Test.stopTest();

        List<LiveText__Conversation_Header__c> conversations = [SELECT Id, LiveText__Transcript_Summary_1__c, LiveText__Transcript_Summary_2__c FROM LiveText__Conversation_Header__c ORDER BY SystemModstamp DESC];

        System.assertEquals(2, conversations.size());
        System.assert(!String.isBlank(conversations[0].LiveText__Transcript_Summary_1__c));
        System.assert(conversations[0].LiveText__Transcript_Summary_1__c.endsWith('<p>Some newer messages</p>'));
        System.assert(conversations[0].LiveText__Transcript_Summary_1__c.contains('href="/' + UserInfo.getUserId() + '"'), 'Expected the transcript to contain a link to the running user');
        System.assert(conversations[0].LiveText__Transcript_Summary_1__c.contains(UserInfo.getName()), 'Expected the transcript to contain the name of the running user');
        System.assert(conversations[0].LiveText__Transcript_Summary_1__c.contains('href="/' + testCase.Id + '"'), 'Expected the transcript to contain a link to the test case');
        System.assert(conversations[0].LiveText__Transcript_Summary_1__c.contains(testCase.CaseNumber), 'Expected the transcript to contain the test case number');

        System.assert(String.isBlank(conversations[0].LiveText__Transcript_Summary_2__c));

        System.assertEquals('<p>Some old messages</p>', conversations[1].LiveText__Transcript_Summary_1__c);
        System.assert(String.isBlank(conversations[1].LiveText__Transcript_Summary_2__c));
    }

    public static LiveText__Conversation_Header__c setupConversation(String transcript) {
        return setupConversation(transcript, null);
    }

    public static LiveText__Conversation_Header__c setupConversation(String transcript1, String transcript2) {
        Case testCase = [SELECT Id, RecordTypeId, ContactId, Status, AccountId FROM Case];

        TestDataFactory.setInsertOBjects(true);
        TestDataFactory.setFieldNameValuePairs('LiveText__Originating_Number__c', 'test');
        TestDataFactory.setFieldNameValuePairs('LiveText__Transcript_Summary_1__c', transcript1);
        TestDataFactory.setFieldNameValuePairs('LiveText__Transcript_Summary_2__c', transcript2);
        TestDataFactory.setFieldNameValuePairs('LiveText__Status__c', 'Ended');
        TestDataFactory.setFieldNameValuePairs('LiveText__Account__c', testCase.AccountId);
        TestDataFactory.setFieldNameValuePairs('LiveText__Case__c', testCase.Id);
        TestDataFactory.setFieldNameValuePairs('Transfer_To_Queue__c', '');

        LiveText__Conversation_Header__c conversation = (LiveText__Conversation_Header__c) TestDataFactory.createSObject('LiveText__Conversation_Header__c');
        TestDataFactory.resetFieldNameValuePairs();

        return conversation;
    }
}