/*------------------------------------------------------------
    Author: Sven Kretschmann
    Company: Salesforce
    Description: Test class for the domain handler for the Case object.
                 Tests executed:
                 1 - testUpdateWithNoClosedCase()
                 Update a case without closing it
                 2 - testCloseWithConversation()
                 Close a case with a conversation
                 3 - testCloseWithMultipleConversations()
                 Close a case with multiple conversation
                 4 - testCaseReassignmentValidation()
                 Case reassignment tests
                 5 - testCaseReassignmentValidationForSuperVisors()
                 Case reassignment tests for supervisors

    History
    <Date>		<Authors Name> 		<Brief Description of Change>
    25.01.2019	Sven Kretschmann    Initial creation with tests
    21.02.2019  Pavel Kalinin       added tests for MOS-448 story
------------------------------------------------------------*/
@IsTest
private with sharing class CaseHandler_Test {

    @TestSetup
    public static void setupTestData() {
        /* we reuse the same data setup, the trigger mostly just executes the service */
        CaseCloseService_Test.setupTestData();
    }

    @IsTest
    public static void testUpdateWithNoClosedCase() {
        Case testCase = [SELECT Id, RecordTypeId, ContactId, Status, AccountId FROM Case];

        CaseCloseService_Test.setupConversation('testTranscript');

        Test.startTest();

        testCase.Status = 'In Progress';
        update testCase;

        Test.stopTest();

        List<LiveText__Conversation_Header__c> conversations = [SELECT Id, LiveText__Transcript_Summary_1__c FROM LiveText__Conversation_Header__c];
        System.assertEquals(1, conversations.size());
        System.assertEquals('testTranscript', conversations[0].LiveText__Transcript_Summary_1__c);
    }

    @IsTest
    public static void testCloseWithConversation() {
        Case testCase = [SELECT Id, CaseNumber, RecordTypeId, ContactId, Status, AccountId, Contact.CustomerId__c FROM Case];

        CaseCloseService_Test.setupConversation('<p>Some existing messages</p>');

        Test.startTest();

        testCase.Status = 'Manual_Close';
        update testCase;

        Test.stopTest();

        List<LiveText__Conversation_Header__c> conversations = [SELECT Id, LiveText__Transcript_Summary_1__c, LiveText__Transcript_Summary_2__c FROM LiveText__Conversation_Header__c];
        System.assertEquals(1, conversations.size());
        System.assert(!String.isBlank(conversations[0].LiveText__Transcript_Summary_1__c));
        System.assert(conversations[0].LiveText__Transcript_Summary_1__c.endsWith('<p>Some existing messages</p>'));
        System.assert(conversations[0].LiveText__Transcript_Summary_1__c.contains(testCase.CaseNumber), 'Expected the transcript to contain the test case number');
    }

    @IsTest
    public static void testCloseWithMultipleConversations() {
        Case testCase = [SELECT Id, CaseNumber, RecordTypeId, ContactId, Status, AccountId, Contact.CustomerId__c FROM Case];

        CaseCloseService_Test.setupConversation('<p>Some old messages</p>');

        /* idle for a second to allow proper sorting of the conversations */
        Datetime start = Datetime.now();

        while (start.second() == Datetime.now().second()) {
            /* noop */
        }

        CaseCloseService_Test.setupConversation('<p>Some newer messages</p>');

        Test.startTest();

        testCase.Status = 'Manual_Close';
        update testCase;

        Test.stopTest();

        List<LiveText__Conversation_Header__c> conversations = [SELECT Id, LiveText__Transcript_Summary_1__c, LiveText__Transcript_Summary_2__c FROM LiveText__Conversation_Header__c ORDER BY SystemModstamp DESC];

        System.assertEquals(2, conversations.size());
        System.assert(!String.isBlank(conversations[0].LiveText__Transcript_Summary_1__c));
        System.assert(conversations[0].LiveText__Transcript_Summary_1__c.endsWith('<p>Some newer messages</p>'));
        System.assert(conversations[0].LiveText__Transcript_Summary_1__c.contains(testCase.CaseNumber), 'Expected the transcript to contain the test case number');

        System.assert(String.isBlank(conversations[0].LiveText__Transcript_Summary_2__c));

        System.assertEquals('<p>Some old messages</p>', conversations[1].LiveText__Transcript_Summary_1__c);
        System.assert(String.isBlank(conversations[1].LiveText__Transcript_Summary_2__c));
    }

    @IsTest
    public static void testCaseReassignmentValidation() {
        final Schema.User runningUser = TestDataFactory.getRunningUser();

        final Group testQueue = TestDataFactory.createQueue('TestQueue', 'Case');

        final TestDataFactory.TestUser testUser = new TestDataFactory.TestUser()
            .assignToGroup(testQueue)
            .assignPermissionSet('LiveMessage_Agent_Standard_Object_Permissions');

        TestDataFactory.setInsertOBjects(true);

        //Account
        TestDataFactory.setFieldNameValuePairs('RecordTypeId', 'LiveMessage');
        TestDataFactory.setFieldNameValuePairs('FirstName', 'Cooper');
        TestDataFactory.setFieldNameValuePairs('LastName', 'Hawkes');
        TestDataFactory.setFieldNameValuePairs('Phone', '+4917620944202');
        TestDataFactory.setFieldNameValuePairs('FacebookId__pc', '2157762154239024');
        Account testAccount = (Account) TestDataFactory.createSObject('Account');
        TestDataFactory.resetFieldNameValuePairs();

        List<Account> testAccounts = [SELECT Id, PersonContactId, Phone, FacebookId__pc FROM Account WHERE Id = :testAccount.Id];
        System.assertEquals(1, testAccounts.size(), 'Results query returned no results');

        System.runAs(testUser.getUser()) {
            //Case
            TestDataFactory.setFieldNameValuePairs('RecordTypeId', 'LiveMessage');
            TestDataFactory.setFieldNameValuePairs('LastAgent__c', '');
            TestDataFactory.setFieldNameValuePairs('OwnerId', testQueue.Id);
            TestDataFactory.setFieldNameValuePairs('ContactId', testAccounts[0].PersonContactId);
            TestDataFactory.setFieldNameValuePairs('Status', 'Open');
            Case testCase = (Case) TestDataFactory.createSObject('Case');
            TestDataFactory.resetFieldNameValuePairs();

            //assign case from queue to user - success
            testCase.OwnerId = UserInfo.getUserId();
            update testCase;

            System.assertEquals(UserInfo.getUserId(), [SELECT OwnerId FROM Case WHERE Id = :testCase.Id].OwnerId);

            //assign case from user to queue - success
            testCase.OwnerId = testQueue.Id;
            update testCase;

            System.assertEquals(testQueue.Id, [SELECT OwnerId FROM Case WHERE Id = :testCase.Id].OwnerId);

            //assign case again from queue to user - success
            testCase.OwnerId = UserInfo.getUserId();
            update testCase;

            System.assertEquals(UserInfo.getUserId(), [SELECT OwnerId FROM Case WHERE Id = :testCase.Id].OwnerId);

            //assign case from user to user without active session - failure
            testCase.OwnerId = runningUser.Id;

            try {
                update testCase;
                System.assert(false, 'Expected an exception to be thrown when changing the case owner from user to user');
            } catch (Exception e) {
                System.assert(e.getMessage().contains(Label.Case_Reassignment_ErrorMsg));
            }

            System.assertNotEquals(runningUser.Id, [SELECT OwnerId FROM Case WHERE Id = :testCase.Id].OwnerId);
            System.assertEquals(UserInfo.getUserId(), [SELECT OwnerId FROM Case WHERE Id = :testCase.Id].OwnerId);

            //assign case from user to user with active session - success
            //LiveText__Conversation_Header__c
            TestDataFactory.setFieldNameValuePairs('LiveText__Originating_Number__c', 'test');
            TestDataFactory.setFieldNameValuePairs('OwnerId', runningUser.Id);
            TestDataFactory.setFieldNameValuePairs('LiveText__Status__c', 'Active');
            TestDataFactory.setFieldNameValuePairs('LiveText__Account__c', testAccount.Id);
            TestDataFactory.setFieldNameValuePairs('LiveText__Case__c', testCase.Id);
            TestDataFactory.setFieldNameValuePairs('Transfer_To_Queue__c', '');
            LiveText__Conversation_Header__c session = (LiveText__Conversation_Header__c) TestDataFactory.createSObject('LiveText__Conversation_Header__c');
            TestDataFactory.resetFieldNameValuePairs();

            testCase.OwnerId = runningUser.Id;
            update testCase;

            System.assertEquals(runningUser.Id, [SELECT OwnerId FROM Case WHERE Id = :testCase.Id].OwnerId);
        }
    }

    @IsTest
    public static void testCaseReassignmentValidationForSupervisors() {
        final Schema.User runningUser = TestDataFactory.getRunningUser();
        final Group testQueue = TestDataFactory.createQueue('TestQueue', 'Case');

        final TestDataFactory.TestUser testUser = new TestDataFactory.TestUser()
            .assignCustomPermission('Case_Reassignment')
            .assignToGroup(testQueue)
            .assignPermissionSets(new Set<String> {
                'LiveMessage_Agent_Standard_Object_Permissions',
                'LiveMessage_Manager_Standard_Object_Permissions'
            });

        TestDataFactory.setInsertOBjects(true);

        //Account
        TestDataFactory.setFieldNameValuePairs('RecordTypeId', 'LiveMessage');
        TestDataFactory.setFieldNameValuePairs('FirstName', 'Cooper');
        TestDataFactory.setFieldNameValuePairs('LastName', 'Hawkes');
        TestDataFactory.setFieldNameValuePairs('Phone', '+4917620944202');
        TestDataFactory.setFieldNameValuePairs('FacebookId__pc', '2157762154239024');
        Account testAccount = (Account) TestDataFactory.createSObject('Account');
        TestDataFactory.resetFieldNameValuePairs();

        List<Account> testAccounts = [SELECT Id, PersonContactId, Phone, FacebookId__pc FROM Account WHERE Id = :testAccount.Id];
        System.assertEquals(1, testAccounts.size(), 'Results query returned no results');

        System.runAs(testUser.getUser()) {
            //Case
            TestDataFactory.setFieldNameValuePairs('RecordTypeId', 'LiveMessage');
            TestDataFactory.setFieldNameValuePairs('LastAgent__c', '');
            TestDataFactory.setFieldNameValuePairs('OwnerId', testQueue.Id);
            TestDataFactory.setFieldNameValuePairs('ContactId', testAccounts[0].PersonContactId);
            TestDataFactory.setFieldNameValuePairs('Status', 'Open');
            Case testCase = (Case) TestDataFactory.createSObject('Case');
            TestDataFactory.resetFieldNameValuePairs();

            //assign case from queue to user - success
            testCase.OwnerId = UserInfo.getUserId();
            update testCase;

            System.assertEquals(UserInfo.getUserId(), [SELECT OwnerId FROM Case WHERE Id = :testCase.Id].OwnerId);

            //assign case from user to user without active session - also success
            testCase.OwnerId = runningUser.Id;
            update testCase;

            System.assertEquals(runningUser.Id, [SELECT OwnerId FROM Case WHERE Id = :testCase.Id].OwnerId);
        }

    }
}