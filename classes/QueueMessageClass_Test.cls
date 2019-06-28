/*------------------------------------------------------------------------
Author:      Pavel Usoltsev
Company:     Salesforce
Description: A test class created to validate class QueueMessageClass
             Tests executed:
             testing of execution queueable job for sending live message
             1 - checkIfOptionNumberIsAssigned_Test()
             Create LiveText__SMS_Message__c record with required fields
             Enqueue this message as job
             Compare received result with expected
History
7/2/18    Pavel Usoltsev   Initial Version
----------------------------------------------------------------------------*/
@isTest
private class QueueMessageClass_Test {

    @isTest
    static void execute_Test() {
        TestDataFactory.setInsertOBjects(true);

        //User
        User testUser = [SELECT Id FROM User WHERE Profile.Name = 'System Administrator'][0];

        //Account
        TestDataFactory.setFieldNameValuePairs('RecordTypeId', 'Person Account');
        TestDataFactory.setFieldNameValuePairs('FirstName', 'Cooper');
        TestDataFactory.setFieldNameValuePairs('LastName', 'Hawkes');
        Account testAccount = (Account) TestDataFactory.createSObject('Account');
        TestDataFactory.resetFieldNameValuePairs();

        LiveText__SMS_Message__c testMessage = new LiveText__SMS_Message__c();
        testMessage.LiveText__Account__c = testAccount.Id;
        testMessage.LiveText__Message_Status__c = 'Sent';
        testMessage.LiveText__Object_Id__c = testAccount.Id;
        testMessage.LiveText__To_Phone_Number__c = '+491733404495';

        List<LiveText__SMS_Message__c> testMessages = new List<LiveText__SMS_Message__c>();
        testMessages.add(testMessage);

        Test.startTest();

        System.enqueueJob(new QueueMessageClass(testMessages));

        Test.stopTest();

        List<LiveText__SMS_Message__c> testMessagesList = [SELECT Id FROM LiveText__SMS_Message__c];
        System.assertEquals(1, testMessagesList.size(), 'Results query returned no results');
    }

}