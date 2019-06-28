/*------------------------------------------------------------
Author: Pavel Usoltsev
Company: Salesforce
Description: A test class created to get the data displayed in the chat component
Tests executed:
             1 - getConversationData()
             Get active session data
             Make SOQL query, which return result of values.
             Compare received result with expected

History
8/10/18    Pavel Usoltsev    Initial Version.
05.02.2019  Sven Kretschmann    Split class from LiveSessionHeaders_CC_Test, improve assertions of tests
------------------------------------------------------------*/
@IsTest
private class ChatScreen_CC_Test {

    @IsTest
    private static void testGetConversationData() {
        TestDataFactory.setInsertOBjects(true);

        TestDataFactory.setFieldNameValuePairs('LiveText__Status__c', 'New');
        TestDataFactory.setFieldNameValuePairs('LiveText__Originating_Number__c', '2157762154239024');
        LiveText__Conversation_Header__c testLiveText = (LiveText__Conversation_Header__c) TestDataFactory.createSObject('LiveText__Conversation_Header__c');
        TestDataFactory.resetFieldNameValuePairs();

        String response = ChatScreen_CC.getConversationData(testLiveText.Id);
        System.assert(response.length() > 0);
        System.assert(response.contains('"type":"LiveText__Conversation_Header__c"'));
        System.assert(response.contains('"Id":"' + testLiveText.Id + '"'));
        System.assert(response.contains('"LiveText__Originating_Number__c":"2157762154239024"'));
    }

    @IsTest
    private static void testGetSMSData() {
        TestDataFactory.setInsertOBjects(true);

        TestDataFactory.setFieldNameValuePairs('LiveText__Message__c', 'test message');
        TestDataFactory.setFieldNameValuePairs('LiveText__Originating_Number__c', '2157762154239024');
        LiveText__SMS_Text__c testSms = (LiveText__SMS_Text__c) TestDataFactory.createSObject('LiveText__SMS_Text__c');
        TestDataFactory.resetFieldNameValuePairs();

        String response = ChatScreen_CC.getSmsData(testSms.Id);

        System.assert(response.length() > 0);
        System.assert(response.contains('"type":"LiveText__SMS_Text__c"'));
        System.assert(response.contains('"Id":"' + testSms.Id + '"'));
        System.assert(response.contains('"LiveText__Message__c":"test message"'));
    }
}