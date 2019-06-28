/*------------------------------------------------------------------------
Author:      Pavel Usoltsev
Company:     Salesforce
Description: A test class created to validate class MessageLiveHandler
             Tests executed:
             1 - checkUpdateIfContactCaseExist_Test()
             Select User with Profile.Name = 'System Administrator',
             Create Account, Contact, Case, LiveText__Conversation_Header__c(session) records with different field values
             Make SOQL query, which return result of values.
             Compare received result with expected
             2 - changeStatusRelatedCase_Test()
             Update LiveText__Conversation_Header__c(session) records.
             Make SOQL query, which return result of values.
             Compare received result with expected
             3 - transferSession_Test()
             Cover session transfer functionality
             Set Transfer_To_Queue__c with id of the queue to transfer and end the session
             Transfer_To_Queue__c should be erased and session become an Active after session update
             4 - assignSessions_Test()
             Cover session assignment functionality
             Sessions are assigned to queues based on related cases and LiveMessage Session Assignment Setting custom metadata type
             5 - processManualAcceptance_Test()
             Cover manual session assignment functionality
             Sessions are assigned to the agent that accepted them
             6 - reopenRelatedCases_Test()
             Cover a functionality to case reopen for a new sessions
History
7/26/18     Pavel Usoltsev    Initial Version
01/23/18    Pavel Kalinin     fix of MOS-246
01/29/18    Pavel Kalinin     implemented MOS-230/MOS-231 stories
02/21/19    Pavel Kalinin     added ut for MOS-445
28.02.2019  Sven Kretschmann  Making all tests run with a dedicated test user.
17.04.2019  Stefano Pramparo  added test case for MOS-523/INC0308876 fix
----------------------------------------------------------------------------*/
@IsTest
private class LiveMessageSessionHandler_Test {

    @IsTest
    static void checkUpdateIfContactCaseExist_Test() {
        //User
        TestDataFactory.setInsertOBjects(true);

        TestDataFactory.TestUser testUser = new TestDataFactory.TestUser();

        //Account
        TestDataFactory.setFieldNameValuePairs('RecordTypeId', 'Person Account');
        TestDataFactory.setFieldNameValuePairs('FirstName', 'Cooper');
        TestDataFactory.setFieldNameValuePairs('LastName', 'Hawkes');
        TestDataFactory.setFieldNameValuePairs('Phone', '+4917620944202');
        TestDataFactory.setFieldNameValuePairs('FacebookId__pc', '2157762154239024');
        Account testAccount = (Account) TestDataFactory.createSObject('Account');
        TestDataFactory.resetFieldNameValuePairs();

        List<Account> testAccounts = [SELECT Id, PersonContactId, Phone, FacebookId__pc FROM Account WHERE Id = :testAccount.Id];
        System.assertEquals(1, testAccounts.size(), 'Results query returned no results');

        List<Contact> testContacts = [SELECT Id, AccountId FROM Contact WHERE Id = :testAccounts[0].PersonContactId];
        System.assertEquals(1, testContacts.size(), 'Results query returned no results');

        //Case
        TestDataFactory.setFieldNameValuePairs('LastAgent__c', testUser.getUser().Id);
        TestDataFactory.setFieldNameValuePairs('ContactId', testAccounts[0].PersonContactId);
        TestDataFactory.setFieldNameValuePairs('Status', 'Open');
        Case testCase = (Case) TestDataFactory.createSObject('Case');
        TestDataFactory.resetFieldNameValuePairs();

        List<Case> caseSelected = [
                SELECT Id, Contact.Phone, Contact.AccountId, Contact.FacebookId__c, LastAgent__c
                FROM Case
                WHERE (Contact.Phone = :testAccounts[0].Phone OR Contact.FacebookId__c = :testAccounts[0].FacebookId__pc)
                AND Status = 'Open'
        ];

        System.assertEquals(1, caseSelected.size(), 'Results query returned no results');

        //LiveText__Conversation_Header__c
        TestDataFactory.setFieldNameValuePairs('LiveText__AcceptedBy__c', testCase.LastAgent__c);
        TestDataFactory.setFieldNameValuePairs('LiveText__Status__c', 'New');
        TestDataFactory.setFieldNameValuePairs('LiveText__Originating_Number__c', '2157762154239024');
        LiveText__Conversation_Header__c testLiveText = (LiveText__Conversation_Header__c) TestDataFactory.createSObject('LiveText__Conversation_Header__c');
        TestDataFactory.resetFieldNameValuePairs();

        List<LiveText__Conversation_Header__c> testLiveTextList = [SELECT Id, LiveText__AcceptedBy__c, LiveText__Case__c FROM LiveText__Conversation_Header__c];
        System.assertEquals(1, testLiveTextList.size(), 'Results query returned no results');
    }

    @IsTest
    static void changeStatusRelatedCase_Test() {
        Group testQueue = TestDataFactory.createQueue('TestQueue', new Set<String>{
                'LiveText__Conversation_Header__c', 'Case'
        });

        TestDataFactory.TestUser testUser = new TestDataFactory.TestUser()
                .assignPermissionSets(new Set<String>{
                        'LiveMessage_Agent_Standard_Object_Permissions',
                        'LiveMessage_Manager_Standard_Object_Permissions'
                })
                .assignCustomPermission('Case_Reassignment')
                .assignToGroup(testQueue);

        TestDataFactory.setInsertOBjects(true);

        TestDataFactory.setFieldNameValuePairs('RecordTypeId', 'Person Account');
        TestDataFactory.setFieldNameValuePairs('LastName', 'Can');
        TestDataFactory.setFieldNameValuePairs('Phone', '+491733465213');
        TestDataFactory.setFieldNameValuePairs('FacebookId__pc', '2157762154239022');
        Account testAccount2 = (Account) TestDataFactory.createSObject('Account');
        TestDataFactory.resetFieldNameValuePairs();

        List<Account> testAccounts2 = [SELECT Id, PersonContactId, Phone, FacebookId__pc FROM Account WHERE Id = :testAccount2.Id];
        System.assertEquals(1, testAccounts2.size(), 'Results query returned no results');

        System.runAs(testUser.getUser()) {
            TestDataFactory.setFieldNameValuePairs('LastAgent__c', testUser.getUser().Id);
            TestDataFactory.setFieldNameValuePairs('ContactId', testAccounts2[0].PersonContactId);
            TestDataFactory.setFieldNameValuePairs('Status', 'Open');
            Case testCase2 = (Case) TestDataFactory.createSObject('Case');
            TestDataFactory.resetFieldNameValuePairs();

            TestDataFactory.setFieldNameValuePairs('LiveText__Account__c', testAccounts2[0].Id);
            TestDataFactory.setFieldNameValuePairs('LiveText__Contact__c', testAccounts2[0].PersonContactId);
            TestDataFactory.setFieldNameValuePairs('LiveText__Case__c', testCase2.Id);
            TestDataFactory.setFieldNameValuePairs('LiveText_LastAgent__c', testCase2.LastAgent__c);
            TestDataFactory.setFieldNameValuePairs('LiveText__AcceptedBy__c', testCase2.LastAgent__c);
            TestDataFactory.setFieldNameValuePairs('LiveText__Status__c', 'Active');
            TestDataFactory.setFieldNameValuePairs('LiveText__Originating_Number__c', '2157762154239024');
            TestDataFactory.setFieldNameValuePairs('Transfer_To_Queue__c', null);
            LiveText__Conversation_Header__c testLiveText2 = (LiveText__Conversation_Header__c) TestDataFactory.createSObject('LiveText__Conversation_Header__c');
            TestDataFactory.resetFieldNameValuePairs();

            testLiveText2.LiveText__Status__c = 'Ended';

            Test.startTest();
            update testLiveText2;

            Case caseAfterSessionClosed = [SELECT Id, Status FROM Case WHERE Id = :testCase2.Id];
            System.debug('Start Test caseAfterSessionClosed' + caseAfterSessionClosed.Status);
            System.assertEquals(LiveMessageSessionHandler.CASE_STATUS_AFTER_SESSION_END, caseAfterSessionClosed.Status);

            Test.stopTest();

            /* now the scheduled action should have closed it */
            /* process builder schdeuled action is not trigger by stoTest
             * caseAfterSessionClosed = [SELECT Id, Status FROM Case WHERE Id = :testCase2.Id];
            System.debug('caseAfterSessionClosed' + caseAfterSessionClosed.status);
            System.assertEquals('Automatic Close', caseAfterSessionClosed.Status);*/
        }
    }

    @IsTest
    static void transferSession_Test() {
        TestDataFactory.TestUser testUser = new TestDataFactory.TestUser();
        testUser.assignPermissionSet('LiveMessage_Agent_Standard_Object_Permissions');

        Group testQueue = TestDataFactory.createQueue('TestQueue', new Set<String>{
                'LiveText__Conversation_Header__c', 'Case'
        });

        TestDataFactory.setInsertOBjects(true);

        //Account
        TestDataFactory.setFieldNameValuePairs('RecordTypeId', 'LiveMessage');
        TestDataFactory.setFieldNameValuePairs('LastName', 'Can');
        TestDataFactory.setFieldNameValuePairs('Phone', '+491733465213');
        TestDataFactory.setFieldNameValuePairs('FacebookId__pc', '2157762154239022');
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

        //LiveText__Conversation_Header__c - to assign to a queue
        TestDataFactory.setFieldNameValuePairs('LiveText__Originating_Number__c', 'test');
        TestDataFactory.setFieldNameValuePairs('LiveText__Status__c', 'Active');
        TestDataFactory.setFieldNameValuePairs('LiveText__Account__c', testAccount.Id);
        TestDataFactory.setFieldNameValuePairs('LiveText__Case__c', testCase.Id);
        TestDataFactory.setFieldNameValuePairs('Transfer_To_Queue__c', testQueue.Id);
        TestDataFactory.setFieldNameValuePairs('OwnerId', testUser.getUser().Id);
        TestDataFactory.setFieldNameValuePairs('LiveText__AcceptedBy__c', testUser.getUser().Id);
        LiveText__Conversation_Header__c sessionToQueue = (LiveText__Conversation_Header__c) TestDataFactory.createSObject('LiveText__Conversation_Header__c');
        TestDataFactory.resetFieldNameValuePairs();

        System.runAs(testUser.getUser()) {
            sessionToQueue.put('LiveText__Status__c', 'Ended');

            Test.startTest();
            update sessionToQueue;
            Test.stopTest();

            LiveText__Conversation_Header__c sessionToQueueAfter = [
                    SELECT Id, LiveText__Status__c, Transfer_To_Queue__c
                    FROM LiveText__Conversation_Header__c
                    WHERE Id = :sessionToQueue.Id
            ];
            System.assertEquals('Active', sessionToQueueAfter.LiveText__Status__c);
            System.assertEquals(null, sessionToQueueAfter.Transfer_To_Queue__c);
        }
    }

    @IsTest
    static void assignSessions_Test() {
        TestDataFactory.setInsertOBjects(true);

        String serviceOption = 'Service';
        String serviceQueueName = 'Care Service';
        String serviceQueueDevName = 'Care_Service';

        //Group
        List<Group> serviceQueue = [SELECT Id, Name, DeveloperName FROM Group WHERE Type = 'Queue' AND DeveloperName = :serviceQueueDevName];
        if (serviceQueue.isEmpty()) {
            serviceQueue.add(new Group(
                    Name = serviceQueueName,
                    DeveloperName = serviceQueueDevName,
                    Type = 'Queue'
            ));
            insert serviceQueue;
        }

        //Account
        TestDataFactory.setFieldNameValuePairs('RecordTypeId', 'LiveMessage');
        TestDataFactory.setFieldNameValuePairs('LastName', 'Can');
        TestDataFactory.setFieldNameValuePairs('Phone', '+491733465213');
        TestDataFactory.setFieldNameValuePairs('FacebookId__pc', '2157762154239022');
        Account testAccount = (Account) TestDataFactory.createSObject('Account');
        TestDataFactory.resetFieldNameValuePairs();

        List<Account> testAccounts = [SELECT Id, PersonContactId, Phone, FacebookId__pc FROM Account WHERE Id = :testAccount.Id];
        System.assertEquals(1, testAccounts.size(), 'Results query returned no results');

        //Case
        TestDataFactory.setFieldNameValuePairs('RecordTypeId', 'LiveMessage');
        TestDataFactory.setFieldNameValuePairs('SupportOption__c', serviceOption);
        TestDataFactory.setFieldNameValuePairs('Is_Retention__c', 'false');
        TestDataFactory.setFieldNameValuePairs('ResponsibleAgencyId__c', null);
        TestDataFactory.setFieldNameValuePairs('ResponsibleAgency__c', null);
        TestDataFactory.setFieldNameValuePairs('ContactId', testAccounts[0].PersonContactId);
        TestDataFactory.setFieldNameValuePairs('Status', 'Open');
        Case testServiceCase = (Case) TestDataFactory.createSObject('Case');
        TestDataFactory.resetFieldNameValuePairs();

        //LiveText__Conversation_Header__c - to assign to a queue
        TestDataFactory.setFieldNameValuePairs('LiveText__Originating_Number__c', 'test');
        TestDataFactory.setFieldNameValuePairs('LiveText__Status__c', 'New');
        TestDataFactory.setFieldNameValuePairs('LiveText__Account__c', testAccount.Id);
        TestDataFactory.setFieldNameValuePairs('LiveText__Case__c', testServiceCase.Id);
        TestDataFactory.setFieldNameValuePairs('ResponsibleAgencyId__c', null);
        TestDataFactory.setFieldNameValuePairs('ResponsibleAgency__c', null);
        LiveText__Conversation_Header__c sessionService = (LiveText__Conversation_Header__c) TestDataFactory.createSObject('LiveText__Conversation_Header__c');
        TestDataFactory.resetFieldNameValuePairs();

        LiveText__Conversation_Header__c sessionAfterAssignment = [SELECT Id, ResponsibleAgencyId__c, ResponsibleAgency__c FROM LiveText__Conversation_Header__c WHERE Id = :sessionService.Id];
        System.assertEquals(serviceQueue[0].Id, sessionAfterAssignment.ResponsibleAgencyId__c);
        System.assertEquals(serviceQueue[0].Name, sessionAfterAssignment.ResponsibleAgency__c);

        String serviceRetentionOption = 'Service';
        String serviceRetentionQueueName = 'Retention Service';
        String serviceRetentionQueueDevName = 'Retention_Service';

        //Group
        List<Group> serviceRetentionQueue = [SELECT Id, Name, DeveloperName FROM Group WHERE Type = 'Queue' AND DeveloperName = :serviceRetentionQueueDevName];
        if (serviceRetentionQueue.isEmpty()) {
            serviceRetentionQueue.add(new Group(
                    Name = serviceRetentionQueueName,
                    DeveloperName = serviceRetentionQueueDevName,
                    Type = 'Queue'
            ));
            insert serviceRetentionQueue;
        }

        //Case
        TestDataFactory.setFieldNameValuePairs('RecordTypeId', 'LiveMessage');
        TestDataFactory.setFieldNameValuePairs('SupportOption__c', serviceRetentionOption);
        TestDataFactory.setFieldNameValuePairs('Is_Retention__c', 'true');
        TestDataFactory.setFieldNameValuePairs('ResponsibleAgencyId__c', null);
        TestDataFactory.setFieldNameValuePairs('ResponsibleAgency__c', null);
        TestDataFactory.setFieldNameValuePairs('ContactId', testAccounts[0].PersonContactId);
        TestDataFactory.setFieldNameValuePairs('Status', 'Open');
        Case testServiceRetentionCase = (Case) TestDataFactory.createSObject('Case');
        TestDataFactory.resetFieldNameValuePairs();

        //LiveText__Conversation_Header__c - to assign to a queue
        TestDataFactory.setFieldNameValuePairs('LiveText__Originating_Number__c', 'test');
        TestDataFactory.setFieldNameValuePairs('LiveText__Status__c', 'New');
        TestDataFactory.setFieldNameValuePairs('LiveText__Account__c', testAccount.Id);
        TestDataFactory.setFieldNameValuePairs('LiveText__Case__c', testServiceRetentionCase.Id);
        TestDataFactory.setFieldNameValuePairs('ResponsibleAgencyId__c', null);
        TestDataFactory.setFieldNameValuePairs('ResponsibleAgency__c', null);
        LiveText__Conversation_Header__c sessionServiceRetention = (LiveText__Conversation_Header__c) TestDataFactory.createSObject('LiveText__Conversation_Header__c');
        TestDataFactory.resetFieldNameValuePairs();

        LiveText__Conversation_Header__c sessionAfterAssignmentRet = [SELECT Id, ResponsibleAgencyId__c, ResponsibleAgency__c FROM LiveText__Conversation_Header__c WHERE Id = :sessionServiceRetention.Id];
        System.assertEquals(serviceRetentionQueue[0].Id, sessionAfterAssignmentRet.ResponsibleAgencyId__c);
        System.assertEquals(serviceRetentionQueue[0].Name, sessionAfterAssignmentRet.ResponsibleAgency__c);
    }

    @IsTest
    static void assignSessionsForPreviouslyRoutedCase_Test() {
        TestDataFactory.setInsertOBjects(true);

        String serviceQueueDevName = 'Care_Service';
        String serviceRetentionQueueDevName = 'Retention_Service';

        List<Group> queues = [
                SELECT
                        Id,
                        Name,
                        DeveloperName
                FROM
                        Group
                WHERE
                Type = 'Queue'
                AND
                (
                        DeveloperName = :serviceQueueDevName
                        OR
                        DeveloperName = :serviceRetentionQueueDevName
                )
        ];

        Map<String, Group> queueMap = new Map<String, Group>();

        for (Group queue : queues) {
            queueMap.put(queue.DeveloperName, queue);
        }

        if (!queueMap.containsKey(serviceQueueDevName)) {
            queueMap.put(serviceQueueDevName, new Group(
                    Name = 'Care Service',
                    DeveloperName = serviceQueueDevName,
                    Type = 'Queue'
            ));

            insert queueMap.get(serviceQueueDevName);
        }

        if (!queueMap.containsKey(serviceRetentionQueueDevName)) {
            queueMap.put(serviceRetentionQueueDevName, new Group(
                    Name = 'Care Service',
                    DeveloperName = serviceRetentionQueueDevName,
                    Type = 'Queue'
            ));

            insert queueMap.get(serviceRetentionQueueDevName);
        }

        //Account
        TestDataFactory.setFieldNameValuePairs('RecordTypeId', 'LiveMessage');
        TestDataFactory.setFieldNameValuePairs('LastName', 'Can');
        TestDataFactory.setFieldNameValuePairs('Phone', '+491733465213');
        TestDataFactory.setFieldNameValuePairs('FacebookId__pc', '2157762154239022');
        Account testAccount = (Account) TestDataFactory.createSObject('Account');
        TestDataFactory.resetFieldNameValuePairs();

        List<Account> testAccounts = [SELECT Id, PersonContactId, Phone, FacebookId__pc FROM Account WHERE Id = :testAccount.Id];
        System.assertEquals(1, testAccounts.size(), 'Results query returned no results');

        //Case
        TestDataFactory.setFieldNameValuePairs('RecordTypeId', 'LiveMessage');
        TestDataFactory.setFieldNameValuePairs('SupportOption__c', 'Service');

        /*
           Because of the retention flag, the conversation would be routed to the retention queue,
           but with the responsible agency we overwrite this.
         */
        TestDataFactory.setFieldNameValuePairs('Is_Retention__c', 'true');
        TestDataFactory.setFieldNameValuePairs('ResponsibleAgencyId__c', queueMap.get(serviceQueueDevName).Id);
        TestDataFactory.setFieldNameValuePairs('ResponsibleAgency__c', queueMap.get(serviceQueueDevName).Name);
        TestDataFactory.setFieldNameValuePairs('ContactId', testAccounts[0].PersonContactId);
        TestDataFactory.setFieldNameValuePairs('Status', 'Open');
        Case testServiceCase = (Case) TestDataFactory.createSObject('Case');
        TestDataFactory.resetFieldNameValuePairs();

        //LiveText__Conversation_Header__c - to assign to a queue
        TestDataFactory.setFieldNameValuePairs('LiveText__Originating_Number__c', 'test');
        TestDataFactory.setFieldNameValuePairs('LiveText__Status__c', 'New');
        TestDataFactory.setFieldNameValuePairs('LiveText__Account__c', testAccount.Id);
        TestDataFactory.setFieldNameValuePairs('LiveText__Case__c', testServiceCase.Id);
        TestDataFactory.setFieldNameValuePairs('ResponsibleAgencyId__c', null);
        TestDataFactory.setFieldNameValuePairs('ResponsibleAgency__c', null);
        LiveText__Conversation_Header__c sessionService = (LiveText__Conversation_Header__c) TestDataFactory.createSObject('LiveText__Conversation_Header__c');
        TestDataFactory.resetFieldNameValuePairs();

        LiveText__Conversation_Header__c sessionAfterAssignment = [SELECT Id, ResponsibleAgencyId__c, ResponsibleAgency__c FROM LiveText__Conversation_Header__c WHERE Id = :sessionService.Id];
        System.assertEquals(queueMap.get(serviceQueueDevName).Id, sessionAfterAssignment.ResponsibleAgencyId__c);
        System.assertEquals(queueMap.get(serviceQueueDevName).Name, sessionAfterAssignment.ResponsibleAgency__c);
    }

    @IsTest
    static void processManualAcceptance_Test() {
        TestDataFactory.setInsertOBjects(true);

        //LiveText__Conversation_Header__c
        TestDataFactory.setFieldNameValuePairs('LiveText__Status__c', 'New');
        TestDataFactory.setFieldNameValuePairs('LiveText__AcceptedBy__c', null);
        TestDataFactory.setFieldNameValuePairs('LiveText__Account__c', null);
        TestDataFactory.setFieldNameValuePairs('LiveText__Case__c', null);
        TestDataFactory.setFieldNameValuePairs('OwnerId', [SELECT Id, Name FROM Group WHERE Type = 'Queue'][0].Id);
        TestDataFactory.setFieldNameValuePairs('LiveText__Originating_Number__c', '2157762154239024');
        LiveText__Conversation_Header__c testLiveText = (LiveText__Conversation_Header__c) TestDataFactory.createSObject('LiveText__Conversation_Header__c');
        TestDataFactory.resetFieldNameValuePairs();

        testLiveText.LiveText__AcceptedBy__c = null;
        update testLiveText;

        Test.startTest();
        testLiveText.LiveText__Status__c = 'Active';
        testLiveText.LiveText__AcceptedBy__c = UserInfo.getUserId();
        update testLiveText;
        Test.stopTest();

        LiveText__Conversation_Header__c testLiveTextAfter = [SELECT Id, LiveText__Status__c, LiveText__AcceptedBy__c, OwnerId FROM LiveText__Conversation_Header__c WHERE Id = :testLiveText.Id];
        System.assertEquals(testLiveTextAfter.LiveText__AcceptedBy__c, testLiveTextAfter.OwnerId);
    }

    @IsTest
    static void reopenRelatedCases_Test() {
        Group testQueue = TestDataFactory.createQueue('TestQueue', new Set<String>{
                'Case', 'LiveText__Conversation_Header__c'
        });

        TestDataFactory.setInsertOBjects(true);

        //Account
        TestDataFactory.setFieldNameValuePairs('RecordTypeId', 'LiveMessage');
        TestDataFactory.setFieldNameValuePairs('LastName', 'Can');
        TestDataFactory.setFieldNameValuePairs('Phone', '+491733465213');
        TestDataFactory.setFieldNameValuePairs('FacebookId__pc', '2157762154239022');
        Account testAccount = (Account) TestDataFactory.createSObject('Account');
        TestDataFactory.resetFieldNameValuePairs();

        List<Account> testAccounts = [SELECT Id, PersonContactId, Phone, FacebookId__pc FROM Account WHERE Id = :testAccount.Id];
        System.assertEquals(1, testAccounts.size(), 'Results query returned no results');

        //Case
        TestDataFactory.setFieldNameValuePairs('RecordTypeId', 'LiveMessage');
        TestDataFactory.setFieldNameValuePairs('Is_Retention__c', 'false');
        TestDataFactory.setFieldNameValuePairs('ResponsibleAgencyId__c', null);
        TestDataFactory.setFieldNameValuePairs('ResponsibleAgency__c', null);
        TestDataFactory.setFieldNameValuePairs('ContactId', testAccounts[0].PersonContactId);
        TestDataFactory.setFieldNameValuePairs('Status', LiveMessageSessionHandler.CASE_STATUS_AFTER_SESSION_END);
        TestDataFactory.setFieldNameValuePairs('OwnerId', testQueue.Id);
        Case testServiceCase = (Case) TestDataFactory.createSObject('Case');
        TestDataFactory.resetFieldNameValuePairs();

        //LiveText__Conversation_Header__c - to assign to a queue
        TestDataFactory.setFieldNameValuePairs('LiveText__Originating_Number__c', 'test');
        TestDataFactory.setFieldNameValuePairs('LiveText__Status__c', 'Active');
        TestDataFactory.setFieldNameValuePairs('LiveText__Account__c', testAccount.Id);
        TestDataFactory.setFieldNameValuePairs('LiveText__Case__c', testServiceCase.Id);
        TestDataFactory.setFieldNameValuePairs('ResponsibleAgencyId__c', null);
        TestDataFactory.setFieldNameValuePairs('ResponsibleAgency__c', null);
        LiveText__Conversation_Header__c sessionService = (LiveText__Conversation_Header__c) TestDataFactory.createSObject('LiveText__Conversation_Header__c');
        TestDataFactory.resetFieldNameValuePairs();

        System.assertEquals(LiveMessageSessionHandler.CASE_STATUS_AFTER_SESSION_START, [SELECT Status FROM Case WHERE Id = :testServiceCase.Id].Status);
    }
    @IsTest
    static void checkAgentReplyPendingSince_Test() {
        TestDataFactory.setInsertOBjects(true);

        //LiveText__Conversation_Header__c
        TestDataFactory.setFieldNameValuePairs('LiveText__Status__c', 'New');
        TestDataFactory.setFieldNameValuePairs('LiveText__AcceptedBy__c', null);
        TestDataFactory.setFieldNameValuePairs('LiveText__Account__c', null);
        TestDataFactory.setFieldNameValuePairs('LiveText__Case__c', null);
        TestDataFactory.setFieldNameValuePairs('OwnerId', [SELECT Id, Name FROM Group WHERE Type = 'Queue'][0].Id);
        TestDataFactory.setFieldNameValuePairs('LiveText__Originating_Number__c', '2157762154239024');
        LiveText__Conversation_Header__c testLiveText = (LiveText__Conversation_Header__c) TestDataFactory.createSObject('LiveText__Conversation_Header__c');
        TestDataFactory.resetFieldNameValuePairs();

        System.assert(!testLiveText.LiveText__isAccepted__c);
        testLiveText.AgentReplyPendingSince__c = Datetime.newInstance(2019, 04, 17, 00, 00, 00);
        update testLiveText;

        Test.startTest();
        testLiveText.LiveText__Status__c = 'Active';
        testLiveText.LiveText__AcceptedBy__c = UserInfo.getUserId();
        testLiveText.LiveText__isAccepted__c=true;
        Datetime currentDatetime = Datetime.now();
        update testLiveText;
        Test.stopTest();

        LiveText__Conversation_Header__c testLiveTextAfter = [SELECT Id, AgentReplyPendingSince__c,LiveText__isAccepted__c FROM LiveText__Conversation_Header__c WHERE Id = :testLiveText.Id];
        Datetime afterAccept=testLiveTextAfter.AgentReplyPendingSince__c;
        System.assert(testLiveTextAfter.LiveText__isAccepted__c);
        System.assertEquals(currentDatetime.format(), afterAccept.format());
    }
}