/*------------------------------------------------------------
Author:      Pavel Kalinin
Company:     Salesforce
Description: A test class for CaseTransfer_CC
             Tests executed:
             1 - testTransfer()
             Transfer case to a queue
             2 - testTransferEndedConversation()
             Transfer case with an ended conversation to a queue
History
1/08/19      Pavel Kalinin    Initial version
1/23/19      Pavel Kalinin    fix of MOS-246
30.01.2019   Sven Kretschmann Add test for trasnferring an ended session
------------------------------------------------------------*/
@IsTest
private class CaseTransfer_CC_Test {

    @IsTest
    public static void testTransfer() {
        TestDataFactory.TestUser testUser = new TestDataFactory.TestUser();
        testUser.assignPermissionSet('LiveMessage_Agent_Standard_Object_Permissions');

        Group testQueue = TestDataFactory.createQueue('TestQueue', new Set<String>{
            'LiveText__Conversation_Header__c', 'Case'
        });

        Id testUserId = testUser.getUser().Id;

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

        //Case
        TestDataFactory.setFieldNameValuePairs('RecordTypeId', 'LiveMessage');
        TestDataFactory.setFieldNameValuePairs('LastAgent__c', testUserId);
        TestDataFactory.setFieldNameValuePairs('OwnerId', testUserId);
        TestDataFactory.setFieldNameValuePairs('ContactId', testAccounts[0].PersonContactId);
        TestDataFactory.setFieldNameValuePairs('Status', 'Open');
        Case testCase = (Case) TestDataFactory.createSObject('Case');
        TestDataFactory.resetFieldNameValuePairs();

        //LiveText__Conversation_Header__c
        TestDataFactory.setFieldNameValuePairs('LiveText__Originating_Number__c', 'test');
        TestDataFactory.setFieldNameValuePairs('LiveText__Status__c', 'Active');
        TestDataFactory.setFieldNameValuePairs('LiveText__Account__c', testAccount.Id);
        TestDataFactory.setFieldNameValuePairs('LiveText__Case__c', testCase.Id);
        TestDataFactory.setFieldNameValuePairs('Transfer_To_Queue__c', '');
        TestDataFactory.setFieldNameValuePairs('OwnerId', testUserId);
        TestDataFactory.setFieldNameValuePairs('LiveText__AcceptedBy__c', testUserId);
        LiveText__Conversation_Header__c session = (LiveText__Conversation_Header__c) TestDataFactory.createSObject('LiveText__Conversation_Header__c');

        TestDataFactory.resetFieldNameValuePairs();

        testCase = [SELECT Id, Status, OwnerId, IsClosed FROM Case WHERE Id = :testCase.Id];
        System.assertNotEquals(null, testCase, 'Results query returned no results');
        System.assertEquals(false, testCase.IsClosed);

        session = [SELECT Id, LiveText__Status__c, LiveText__Case__c, OwnerId FROM LiveText__Conversation_Header__c];

        System.assertEquals(testUserId, session.OwnerId);
        System.assertEquals(testCase.Id, session.LiveText__Case__c);
        System.assertEquals('Active', session.LiveText__Status__c);

        System.runAs(testUser.getUser()) {
            CaseTransfer_CC controller = new CaseTransfer_CC(new ApexPages.StandardController(testCase));
            controller.transfer();
            System.assertEquals(false, controller.isTransferred);

            controller.selectedQueue = testQueue.Id;
            controller.comment = 'test comment';
            controller.transfer();

            System.debug(ApexPages.getMessages());
            System.assertEquals(true, controller.isTransferred);

            Case caseAfterTransfer = [SELECT Id, Status, OwnerId, IsClosed FROM Case WHERE Id = :testCase.Id LIMIT 1];
            System.assertEquals('Waiting for Transfer', caseAfterTransfer.Status);
            System.assertEquals(controller.selectedQueue, caseAfterTransfer.OwnerId);

            CaseComment commentAfterTransfer = [SELECT Id, CommentBody FROM CaseComment WHERE ParentId = :testCase.Id LIMIT 1];
            System.assertEquals(controller.comment, commentAfterTransfer.CommentBody);

            LiveText__Conversation_Header__c sessionAfterTransfer = [SELECT Id, Transfer_To_Queue__c, LiveText__Status__c FROM LiveText__Conversation_Header__c];
            System.assertEquals(null, sessionAfterTransfer.Transfer_To_Queue__c); //this is set in LiveMessageSessionHandler
            System.assertEquals('Active', sessionAfterTransfer.LiveText__Status__c); //this is set in LiveMessageSessionHandler
        }
    }

    @IsTest
    public static void testTransferEndedConversation() {
        TestDataFactory.TestUser testUser = new TestDataFactory.TestUser();
        testUser.assignPermissionSet('LiveMessage_Agent_Standard_Object_Permissions');

        Group testQueue = TestDataFactory.createQueue('TestQueue', new Set<String>{
            'LiveText__Conversation_Header__c', 'Case'
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

        //Case
        TestDataFactory.setFieldNameValuePairs('RecordTypeId', 'LiveMessage');
        TestDataFactory.setFieldNameValuePairs('LastAgent__c', testUser.getUser().Id);
        TestDataFactory.setFieldNameValuePairs('OwnerId', testUser.getUser().Id);
        TestDataFactory.setFieldNameValuePairs('ContactId', testAccounts[0].PersonContactId);
        TestDataFactory.setFieldNameValuePairs('Status', 'Open');
        Case testCase = (Case) TestDataFactory.createSObject('Case');
        TestDataFactory.resetFieldNameValuePairs();

        //LiveText__Conversation_Header__c
        TestDataFactory.setFieldNameValuePairs('LiveText__Originating_Number__c', 'test');
        TestDataFactory.setFieldNameValuePairs('LiveText__Status__c', 'Ended');
        TestDataFactory.setFieldNameValuePairs('LiveText__Account__c', testAccount.Id);
        TestDataFactory.setFieldNameValuePairs('LiveText__Case__c', testCase.Id);
        TestDataFactory.setFieldNameValuePairs('Transfer_To_Queue__c', '');
        TestDataFactory.setFieldNameValuePairs('OwnerId', testUser.getUser().Id);
        LiveText__Conversation_Header__c session = (LiveText__Conversation_Header__c) TestDataFactory.createSObject('LiveText__Conversation_Header__c');
        TestDataFactory.resetFieldNameValuePairs();

        List<Case> testCases = [SELECT Id, Status, OwnerId, IsClosed FROM Case WHERE Id = :testCase.Id];
        System.assertEquals(1, testCases.size(), 'Results query returned no results');

        System.runAs(testUser.getUser()) {
            CaseTransfer_CC controller = new CaseTransfer_CC(new ApexPages.StandardController(testCases[0]));
            controller.transfer();
            System.assertEquals(false, controller.isTransferred);

            controller.selectedQueue = testQueue.Id;
            controller.comment = 'test comment';
            controller.transfer();
            System.assertEquals(true, controller.isTransferred);

            Case caseAfterTransfer = [SELECT Id, Status, OwnerId,IsClosed FROM Case WHERE Id = :testCase.Id LIMIT 1];
            System.assertEquals('Waiting for Transfer', caseAfterTransfer.Status);
            System.assertEquals(controller.selectedQueue, caseAfterTransfer.OwnerId);

            CaseComment commentAfterTransfer = [SELECT Id, CommentBody FROM CaseComment WHERE ParentId = :testCase.Id LIMIT 1];
            System.assertEquals(controller.comment, commentAfterTransfer.CommentBody);

            LiveText__Conversation_Header__c sessionAfterTransfer = [SELECT Id, Transfer_To_Queue__c, LiveText__Status__c FROM LiveText__Conversation_Header__c];
            System.assertEquals(null, sessionAfterTransfer.Transfer_To_Queue__c); //this is set in LiveMessageSessionHandler
            System.assertEquals('Active', sessionAfterTransfer.LiveText__Status__c); //this is set in LiveMessageSessionHandler
        }
    }
}