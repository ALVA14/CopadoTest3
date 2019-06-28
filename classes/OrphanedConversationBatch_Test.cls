/*------------------------------------------------------------
Author:      Sven Kretschmann
Company:     Salesforce
Description: Handle all orphaned conversations (active at an offline user)
Inputs:      All active conversations
Tests:       1) Test execution for two conversations: waiting for customer, waiting for agent

History
15.02.2019   Sven Kretschmann   Initial Version
------------------------------------------------------------*/
@IsTest
public with sharing class OrphanedConversationBatch_Test {

    @IsTest
    public static void testExecute() {
        TestDataFactory.setInsertOBjects(true);

        User testUser = [SELECT Id FROM User WHERE Profile.Name = 'System Administrator' AND IsActive = TRUE][0];

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
        TestDataFactory.setFieldNameValuePairs('LastAgent__c', testUser.Id);
        TestDataFactory.setFieldNameValuePairs('ContactId', testAccounts[0].PersonContactId);
        TestDataFactory.setFieldNameValuePairs('Status', 'Open');
        TestDataFactory.setFieldNameValuePairs('SupportOption__c', 'Service');
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
        TestDataFactory.setFieldNameValuePairs('OwnerId', testCase.LastAgent__c);
        TestDataFactory.setFieldNameValuePairs('LiveText__AcceptedBy__c', testCase.LastAgent__c);
        TestDataFactory.setFieldNameValuePairs('LiveText__Status__c', 'Active');
        TestDataFactory.setFieldNameValuePairs('LiveText__Account__c', testAccounts[0].Id);
        TestDataFactory.setFieldNameValuePairs('LiveText__Case__c', caseSelected[0].Id);
        TestDataFactory.setFieldNameValuePairs('LiveText__Status__c', 'Active');
        TestDataFactory.setFieldNameValuePairs('LiveText__Originating_Number__c', '2157762154239024');
        TestDataFactory.setFieldNameValuePairs('LastMessageReceived__c', String.valueOf(Datetime.now().addMinutes(-4)));
        TestDataFactory.setFieldNameValuePairs('LastMessageSent__c', String.valueOf(Datetime.now().addMinutes(-10)));
        LiveText__Conversation_Header__c expectedNewConversation = (LiveText__Conversation_Header__c) TestDataFactory.createSObject('LiveText__Conversation_Header__c');
        TestDataFactory.resetFieldNameValuePairs();

        TestDataFactory.setFieldNameValuePairs('OwnerId', testCase.LastAgent__c);
        TestDataFactory.setFieldNameValuePairs('LiveText__AcceptedBy__c', testCase.LastAgent__c);
        TestDataFactory.setFieldNameValuePairs('LiveText__Status__c', 'Active');
        TestDataFactory.setFieldNameValuePairs('LiveText__Account__c', testAccounts[0].Id);
        TestDataFactory.setFieldNameValuePairs('LiveText__Case__c', caseSelected[0].Id);
        TestDataFactory.setFieldNameValuePairs('LiveText__Status__c', 'Active');
        TestDataFactory.setFieldNameValuePairs('LiveText__Originating_Number__c', '2157762154239024');
        TestDataFactory.setFieldNameValuePairs('LastMessageSent__c', String.valueOf(Datetime.now().addMinutes(-4)));
        TestDataFactory.setFieldNameValuePairs('LastMessageReceived__c', String.valueOf(Datetime.now().addMinutes(-10)));
        LiveText__Conversation_Header__c expectedEndedConversation = (LiveText__Conversation_Header__c) TestDataFactory.createSObject('LiveText__Conversation_Header__c');
        TestDataFactory.resetFieldNameValuePairs();

        Test.startTest();
        Database.executeBatch(new OrphanedConversationBatch());
        Test.stopTest();

        LiveText__Conversation_Header__c actualNewConversation = [SELECT Id, LiveText__Status__c, LiveText__AcceptedBy__c, OwnerId FROM LiveText__Conversation_Header__c WHERE Id = :expectedNewConversation.Id];
        LiveText__Conversation_Header__c actualEndedConversation = [SELECT Id, LiveText__Status__c, LiveText__AcceptedBy__c, OwnerId FROM LiveText__Conversation_Header__c WHERE Id = :expectedEndedConversation.Id];

        System.assertNotEquals(null, actualNewConversation);
        System.assertNotEquals(null, actualEndedConversation);

        System.assertEquals('New', actualNewConversation.LiveText__Status__c);
        System.assertEquals(null, actualNewConversation.LiveText__AcceptedBy__c);
        System.assertNotEquals(expectedNewConversation.OwnerId, actualNewConversation.OwnerId);

        System.assertEquals('Ended', actualEndedConversation.LiveText__Status__c);
        System.assertEquals(expectedEndedConversation.LiveText__AcceptedBy__c, actualEndedConversation.LiveText__AcceptedBy__c);
        System.assertEquals(expectedEndedConversation.OwnerId, actualEndedConversation.OwnerId);
    }
}