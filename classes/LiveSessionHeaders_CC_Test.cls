/*------------------------------------------------------------
Author: Pavel Usoltsev
Company: Salesforce
Description: A test class created to get the data displayed in the chat component
Tests executed:
             1 - getLiveQueues()
             Get live queues
             Make SOQL query, which return result of values.
             Compare received result with expected
             3 - getActiveSessions()
             Get active session data
             Make SOQL query, which return result of values.
             Compare received result with expected
             4 - getNewSessions()
             Get new session data
             Make SOQL query, which return result of values.
             Compare received result with expected

History
8/10/18    Pavel Usoltsev    Initial Version.
05.02.2019  Sven Kretschmann    Adjustments after refactoring the controller class, no real changes
------------------------------------------------------------*/
@IsTest
private class LiveSessionHeaders_CC_Test {

    @IsTest
    private static void getLiveQueues() {
        /* we select a user which is a member of the affected queues to run the tests with to make sure it works as expected */
        QueueSobject[] queues = [SELECT QueueId, Queue.Name FROM QueueSobject WHERE SobjectType = 'LiveText__Conversation_Header__c' ORDER BY Queue.Name ASC];

        Set<Id> queueIds = new Set<Id>();

        for (QueueSobject queue : queues) {
            queueIds.add(queue.QueueId);
        }

        GroupMember membership = [SELECT Id, UserOrGroupId FROM GroupMember WHERE GroupId IN :queueIds LIMIT 1];

        User hostage = [SELECT Id FROM User WHERE Id = :membership.UserOrGroupId LIMIT 1];

        System.runAs(hostage) {
            Test.startTest();
            System.assertEquals(LiveSessionHeaders_CC.getLiveQueues().size() > 0, true);
            Test.stopTest();
        }
    }

    @IsTest
    private static void getActiveSessions() {
        User currentUser = [SELECT Id, Division FROM User WHERE Id = :UserInfo.getUserId() LIMIT 1];

        String testDivision = String.isBlank(currentUser.Division) ? 'test' : currentUser.Division + '-test';

        Group gr = new Group(Name = 'Test');
        User usr;

        System.runAs(currentUser) {
            insert gr;

            TestDataFactory.setFieldNameValuePairs('Division', testDivision);
            usr = TestDataFactory.createActiveUser();

            GroupMember membership = new GroupMember(
                GroupId = gr.Id,
                UserOrGroupId = usr.Id
            );

            insert membership;
        }

        Test.startTest();

        TestDataFactory.setFieldNameValuePairs('LiveText__AcceptedBy__c', usr.Id);
        TestDataFactory.setFieldNameValuePairs('LiveText__Status__c', 'Active');
        TestDataFactory.setFieldNameValuePairs('LiveText__Originating_Number__c', '2157762154239024');
        TestDataFactory.setInsertOBjects(true);
        TestDataFactory.createSObject('LiveText__Conversation_Header__c');

        /* not the same division, it should be empty */
        System.assert(LiveSessionHeaders_CC.getActiveSessions(gr.Id).isEmpty());

        usr.Division = currentUser.Division;
        update usr;

        /* same division, the session should be returned */
        System.assertEquals(1, LiveSessionHeaders_CC.getActiveSessions(gr.Id).size());

        Test.stopTest();
    }

    @IsTest
    private static void getNewSessions() {

        TestDataFactory.setFieldNameValuePairs('LiveText__Status__c', 'New');
        TestDataFactory.setFieldNameValuePairs('LiveText__Originating_Number__c', '2157762154239024');
        LiveText__Conversation_Header__c testLiveText = (LiveText__Conversation_Header__c) TestDataFactory.createSObject('LiveText__Conversation_Header__c');
        TestDataFactory.resetFieldNameValuePairs();

        Group gr = new Group(Name = 'Test');

        insert gr;

        String response = JSON.serialize(LiveSessionHeaders_CC.getActiveSessions(gr.Id));

        System.assertEquals(LiveSessionHeaders_CC.getNewActiveSessions(testLiveText.Id, response, gr.Id).size() > 0, false);
    }

    @IsTest
    private static void getConfiguration() {
        LiveSessionHeaders_CC.ConfigurationDTO config = LiveSessionHeaders_CC.getConfiguration();

        System.assertNotEquals(null, config);
        System.assert(!String.isBlank(config.sessionId));
        System.assertEquals(System.Url.getSalesforceBaseUrl().toExternalForm(), config.baseUrl);
    }

}