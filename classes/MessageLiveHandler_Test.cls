/*------------------------------------------------------------------------
Author:      Pavel Usoltsev
Company:     Salesforce
Description: A test class created to validate class MessageLiveHandler
             Tests executed:
             1 - static void setup()
             Create MessageLive__c records with different field values
             Make SOQL query, which return result List<MessageLive__c>
             Compare received result with expected
             2 - checkOneTypeLiveMessageActive_Test()
             Try insert MessageLive__c record with given fields
             If the values ​​of the fields do not coincide with the condition
             Get DmlException and compare received message with expected message
History
7/28/18   Pavel Usoltsev    Initial Version
----------------------------------------------------------------------------*/
@isTest
private class MessageLiveHandler_Test {


    @isTest
    static void checkOneTypeLiveMessageActive_Test() {

        Test.StartTest();

        LiveText__LiveText_Number__c liveTextNumber = new LiveText__LiveText_Number__c();

        liveTextNumber.LiveText__Channel_Type__c = 'Facebook';
        liveTextNumber.LiveText__Number__c = '276066612726242';

        insert liveTextNumber;

        TestDataFactory.setInsertOBjects(true);

        TestDataFactory.setFieldNameValuePairs('Active__c', 'true');
        TestDataFactory.setFieldNameValuePairs('LiveMessageNumber__c', liveTextNumber.Id);
        TestDataFactory.setFieldNameValuePairs('RecordTypeId','MessageCustomCustomerMessage');

        MessageLive__c testMessageLive3 = (MessageLive__c) TestDataFactory.createSObject('MessageLive__c');

        System.debug('MESSAGE LIVE: ' + testMessageLive3);

        TestDataFactory.resetFieldNameValuePairs();

        try {
            TestDataFactory.setFieldNameValuePairs('Active__c', 'true');
            TestDataFactory.setFieldNameValuePairs('RecordTypeId','MessageCustomCustomerMessage');
            TestDataFactory.setFieldNameValuePairs('LiveMessageNumber__c', liveTextNumber.Id);

            MessageLive__c testMessageLive4 = (MessageLive__c) TestDataFactory.createSObject('MessageLive__c');
            TestDataFactory.resetFieldNameValuePairs();

        } catch (Exception e) {
            system.assertEquals('Insert failed. First exception on row 0; first error: FIELD_CUSTOM_VALIDATION_EXCEPTION, The message with this type already activated!: []', e.getMessage());
        }

        Test.StopTest();

    }

}