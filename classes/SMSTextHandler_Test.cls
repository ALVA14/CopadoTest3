/*------------------------------------------------------------------------
Author: 	 Pavel Usoltsev
Company:     Salesforce
Description: A test class created to validate class SendMessageJob
             Tests executed:
             1 - testFirstFBMessageWithoutAccount()
             First facebook message from customer and there is no person account in sf yet - create person account for customer
             2 - testFirstSMSMessageWithoutAccount()
             First sms message from customer and there is no person account in sf yet - create person account for customer
             3 - testFirstFBMessageWithAccount()
             First facebook message from customer and there is person account in sf - link person account to livemessage session
             4 - testCheckCustomerNumberRetry()
             Customer entered incorrect id - retry field on account is updated
             5 - testCheckCustomerNumber()
             Customer entered correct id - retry field on account is not updated
             6 - testSelectOptionRetry()
             Customer selects incorrect option - option retry field on account is updated, a new case is not created
             7 - testSelectOption()
             Customer selects correct option - a new case is created
             8 - testSelectOptionRetention()
             Retention customer selects correct option - a new case is created, case have to be marked as retention (Is_Retention__c == true)
History
7/28/18     Pavel Usoltsev   Initial Version
18/01/18    Pavel Kalinin    Fixed bug from MOS-221/MOS-229
21/01/18    Pavel Kalinin    Implemented MOS-220/MOS-227
13.03.2019  Stefano Pramparo Added assertion to test that CustomerRowId is not null
----------------------------------------------------------------------------*/
@isTest
private class SMSTextHandler_Test {

    private static final String TEST_CUSTOMER_NUMBER = '1234567890'; //test customer's id
    private static final String TEST_FB_ID = '1111111111111111'; //test customer's facebook id
    private static final String TEST_PHONE_NUMBER = '+111111111111'; //test customer's phone number
    private static final String GET_CUSTOMER_SERVICE_DATA_RESPONSE_NO_FOUND = '{"RetCode":"80","ErrorDesc":"Customer not found"}'; //mock customer service response body for customer not found response
    private static final String GET_CUSTOMER_SERVICE_DATA_RESPONSE = '' + //mock customer service response body
        '{ ' +
        '    "Input" : { ' +
        '        "InputType" : "Customer Number", ' +
        '        "InputNumber" : "' + TEST_CUSTOMER_NUMBER + '" ' +
        '    }, ' +
        '    "Customer" : [ ' +
        '        { ' +
        '            "CompleteCustomerFlag" : "1", ' +
        '            "CustomerNumber" : "' + TEST_CUSTOMER_NUMBER + '", ' +
        '            "CRMType" : "QQQ", ' +
        '            "CustomerStatus" : "AKTIV", ' +
        '            "Contract" : [ ' +
        '                { ' +
        '                    "ContractNumber" : "11111111", ' +
        '                    "Asset" : [' +
        '                        { ' +
        '                            "asset_num" : "11111111111111", ' +
        '                            "asset_type" : "TEST TYPE" ' +
        '                        } ' +
        '                    ], ' +
        '                    "CompleteContractFlag" : "1" ' +
        '                }, ' +
        '                { ' +
        '                    "ContractNumber" : "22222222", ' +
        '                    "Asset" : [ ' +
        '                        { ' +
        '                            "asset_num" : "22222222222222", ' +
        '                            "asset_type" : "TEST TYPE" ' +
        '                        } ' +
        '                    ], ' +
        '                    "CompleteContractFlag" : "1" ' +
        '                } ' +
        '            ], ' +
        '			   "CustomerRowId" : "2-1234" '+ 
        '        } ' +
        '    ] ' +
        '}';

    private static final String GET_CUSTOMER_DATA_RESPONSE = '' + //mock customer data response body
        '{ ' +
        '    "RetCode" : "0", ' +
        '    "ErrorDesc" : "Success", ' +
        '    "CustomerData" : { ' +
        '        "CustomerCategory" : "STANDARD", ' +
        '        "Firstname" : "CRMDREIHUNDERTVIERZEHN", ' +
        '        "Lastname" : "UAT-PP18 CRM-DE", ' +
        '        "CustomerStatus" : "AKTIV", ' +
        '        "skyPinSet" : "true", ' +
        '        "WebLoginFlag" : "true", ' +
        '        "Country" : "DEUTSCHLAND", ' +
        '        "ZipCode" : "85783", ' +
        '        "CustomerMigration" : "Y", ' +
        '        "HotelFlag" : "N", ' +
        '        "SportbarFlag" : "N", ' +
        '        "NumberOfActiveContracts" : "0", ' +
        '        "LastContactReason" : "KÜNDIGUNGSRÜCKNAHME", ' +
        '        "LastContactDate" : "2018-11-12T11:11:29+01:00", ' +
        '        "MultipleContactList" : {}, ' +
        '        "ContractList" : {}, ' +
        '        "skyGoDeviceList" : null, ' +
        '        "STBDiagnosticDataList" : null, ' +
        '        "futureChangeContactFlag" : "false", ' +
        '        "isDeviceListSkyFull" : "N", ' +
        '        "isDeviceListTicketFull" : "N", ' +
        '        "emailAddress" : "test.test@sky.de", ' +
        '        "dateOfBirth" : "12/12/1990", ' +
        '        "CampaignList" : {} ' +
        '    } ' +
        '}';

    private static final String GET_CUSTOMER_DATA_RESPONSE_RETENTION = '' + //mock customer data retention response body
        '{ ' +
        '    "RetCode" : "0", ' +
        '    "ErrorDesc" : "Success", ' +
        '    "CustomerData" : { ' +
        '        "CustomerCategory" : "STANDARD", ' +
        '        "Firstname" : "CRMDREIHUNDERTVIERZEHN", ' +
        '        "Lastname" : "UAT-PP18 CRM-DE", ' +
        '        "CustomerStatus" : "AKTIV", ' +
        '        "skyPinSet" : "true", ' +
        '        "WebLoginFlag" : "true", ' +
        '        "Country" : "DEUTSCHLAND", ' +
        '        "ZipCode" : "85783", ' +
        '        "CustomerMigration" : "Y", ' +
        '        "HotelFlag" : "N", ' +
        '        "SportbarFlag" : "N", ' +
        '        "NumberOfActiveContracts" : "0", ' +
        '        "LastContactReason" : "KÜNDIGUNGSRÜCKNAHME", ' +
        '        "LastContactDate" : "2018-11-12T11:11:29+01:00", ' +
        '        "MultipleContactList" : {}, ' +
        '        "ContractList" : {}, ' +
        '        "skyGoDeviceList" : null, ' +
        '        "STBDiagnosticDataList" : null, ' +
        '        "futureChangeContactFlag" : "false", ' +
        '        "isDeviceListSkyFull" : "N", ' +
        '        "isDeviceListTicketFull" : "N", ' +
        '        "emailAddress" : "test.test@sky.de", ' +
        '        "dateOfBirth" : "12/12/1990", ' +
        '        "CampaignList" : { ' +
        '            "CampaignElement" : { ' +
        '                "CampaignType":"KÜMA", ' +
        '                "CampaignFamily":"REGULÄR STEP2", ' +
        '                "CampaignNumber":"2-22222222222" ' +
        '            } ' +
        '        } ' +
        '    } ' +
        '}';

    @testSetup
    static void setup() {
        TestDataFactory.setInsertOBjects(true);

        //LiveText__LiveText_Number__c
        TestDataFactory.setFieldNameValuePairs('LiveText__Channel_Type__c', 'Facebook');
        TestDataFactory.setFieldNameValuePairs('LiveText__Number__c', '1111111111111112');
        LiveText__LiveText_Number__c liveTextNumberFB = (LiveText__LiveText_Number__c) TestDataFactory.createSObject('LiveText__LiveText_Number__c');
        TestDataFactory.resetFieldNameValuePairs();

        TestDataFactory.setFieldNameValuePairs('LiveText__Channel_Type__c', 'Text');
        TestDataFactory.setFieldNameValuePairs('LiveText__Number__c', '+111111111112');
        LiveText__LiveText_Number__c liveTextNumberSMS = (LiveText__LiveText_Number__c) TestDataFactory.createSObject('LiveText__LiveText_Number__c');
        TestDataFactory.resetFieldNameValuePairs();

        //MessageLive__c
        TestDataFactory.setFieldNameValuePairs('RecordTypeId', 'Limit Message SMS');
        TestDataFactory.setFieldNameValuePairs('Active__c', 'false');
        TestDataFactory.setFieldNameValuePairs('Message__c', 'You have exceeded your number of SMS retries for the day');
        MessageLive__c testMessageLive1 = (MessageLive__c) TestDataFactory.createSObject('MessageLive__c');
        TestDataFactory.resetFieldNameValuePairs();

        TestDataFactory.setFieldNameValuePairs('RecordTypeId', 'Limit Message Facebook');
        TestDataFactory.setFieldNameValuePairs('Active__c', 'false');
        TestDataFactory.setFieldNameValuePairs('Message__c', 'You have exceeded your number of retries for the day');
        MessageLive__c testMessageLive2 = (MessageLive__c) TestDataFactory.createSObject('MessageLive__c');
        TestDataFactory.resetFieldNameValuePairs();

        TestDataFactory.setFieldNameValuePairs('RecordTypeId', 'DefaultOptionMessage');
        TestDataFactory.setFieldNameValuePairs('Active__c', 'false');
        TestDataFactory.setFieldNameValuePairs('Starting_Line__c', 'Please Set the options give below');
        TestDataFactory.setFieldNameValuePairs('Ending_Line__c', 'Select the option');
        TestDataFactory.setFieldNameValuePairs('Message_Retry__c', 'Incorrect Option has been selected. Please choose again');
        MessageLive__c testMessageLive3 = (MessageLive__c) TestDataFactory.createSObject('MessageLive__c');
        TestDataFactory.resetFieldNameValuePairs();

        TestDataFactory.setFieldNameValuePairs('RecordTypeId', 'MessageCustomCustomerMessage');
        TestDataFactory.setFieldNameValuePairs('LiveMessageNumber__c', liveTextNumberFB.Id);
        TestDataFactory.setFieldNameValuePairs('Active__c', 'true');
        TestDataFactory.setFieldNameValuePairs('Message__c', 'Please provide your customer Id as a 10 digit number');
        TestDataFactory.setFieldNameValuePairs('Message_Retry__c', 'please try again');
        MessageLive__c testMessageLive4 = (MessageLive__c) TestDataFactory.createSObject('MessageLive__c');
        TestDataFactory.resetFieldNameValuePairs();

        TestDataFactory.setFieldNameValuePairs('RecordTypeId', 'DefaultCustomerMessage');
        TestDataFactory.setFieldNameValuePairs('Active__c', 'false');
        TestDataFactory.setFieldNameValuePairs('Message__c', 'Please Send us your 10 digit Customer Number as just 1234');
        TestDataFactory.setFieldNameValuePairs('Message_Retry__c', 'Incorrect choose.');
        MessageLive__c testMessageLive5 = (MessageLive__c) TestDataFactory.createSObject('MessageLive__c');
        TestDataFactory.resetFieldNameValuePairs();

        TestDataFactory.setFieldNameValuePairs('RecordTypeId', 'MessageCustomOptionMessage');
        TestDataFactory.setFieldNameValuePairs('LiveMessageNumber__c', liveTextNumberSMS.Id);
        TestDataFactory.setFieldNameValuePairs('Active__c', 'true');
        TestDataFactory.setFieldNameValuePairs('Starting_Line__c', 'Please Set the options give below');
        TestDataFactory.setFieldNameValuePairs('Ending_Line__c', 'Select the option');
        TestDataFactory.setFieldNameValuePairs('Message_Retry__c', 'Incorrect Option has been selected. Please choose again');
        MessageLive__c testMessageLive6 = (MessageLive__c) TestDataFactory.createSObject('MessageLive__c');
        TestDataFactory.resetFieldNameValuePairs();

        System.assertEquals(6, [SELECT Id FROM MessageLive__c].size(), 'Some errors were occured while preparing messages.');

        //Option__c
        List<Option__c> options = new List<Option__c>{
            new Option__c(
                Name = 'Service',
                Option_No__c = '1',
                MessageLive__c = testMessageLive3.Id
            ),
            new Option__c(
                Name = 'Technics',
                Option_No__c = '2',
                MessageLive__c = testMessageLive3.Id
            ),
            new Option__c(
                Name = 'Sky Ticket',
                Option_No__c = '3',
                MessageLive__c = testMessageLive3.Id
            ),
            new Option__c(
                Name = 'Gewinnspiel',
                Option_No__c = '4',
                MessageLive__c = testMessageLive3.Id
            ),
            new Option__c(
                Name = 'Service',
                Option_No__c = '1',
                MessageLive__c = testMessageLive6.Id
            ),
            new Option__c(
                Name = 'Technics',
                Option_No__c = '2',
                MessageLive__c = testMessageLive6.Id
            ),
            new Option__c(
                Name = 'Sky Ticket',
                Option_No__c = '3',
                MessageLive__c = testMessageLive6.Id
            )
        };
        insert options;

        System.assertEquals(7, [SELECT Id FROM Option__c].size(), 'Some errors were occured while preparing options.');

        //Group
        if ([SELECT Id, OwnerId FROM Group WHERE Type = 'Queue' AND Name = 'OmniQueueLv1'].isEmpty()) {
            insert new Group(Name = 'OmniQueueLv1', Type = 'Queue');
        }

        LiveMessageSettings__c testLiveMessageSettings = new LiveMessageSettings__c(
            CustomerNumberRegEx__c = '^\\d{10}$',
            CustomerDataURL__c = 'https://url.com',
            IdleMessageTime__c = 30000,
            RetentionCampaignType__c = 'KÜMA',
            NumberOfFacebookRetries__c = 5,
            MinutesToBlockAfterFbRetriesLimit__c = 15,
            NumberOfRetries__c = 5,
            MinutesToBlockAfterRetriesLimit__c = 15
        );
        insert testLiveMessageSettings;
    }

    @isTest
    static void testFirstFBMessageWithoutAccount() { // first facebook message from customer and there is no person account in sf yet
        String fbChannelId = [SELECT Id FROM LiveText__LiveText_Number__c WHERE LiveText__Channel_Type__c = 'Facebook' LIMIT 1].Id;

        TestDataFactory.setInsertOBjects(true);

        //LiveText__Conversation_Header__c
        TestDataFactory.setFieldNameValuePairs('LiveText__Support_Number__c', fbChannelId);
        TestDataFactory.setFieldNameValuePairs('LiveText__Originating_Number__c', TEST_FB_ID);
        TestDataFactory.setFieldNameValuePairs('LiveText__Status__c', 'New');
        LiveText__Conversation_Header__c session = (LiveText__Conversation_Header__c) TestDataFactory.createSObject('LiveText__Conversation_Header__c');
        TestDataFactory.resetFieldNameValuePairs();

        System.assertEquals(0, [SELECT Id, FacebookId__pc FROM Account].size());
        System.assertEquals(null, [SELECT Id, LiveText__Account__c FROM LiveText__Conversation_Header__c WHERE Id = :session.Id].LiveText__Account__c);

        Test.startTest();

        SendMessageJob.doChainJob = false;

        //LiveText__SMS_Text__c
        TestDataFactory.setFieldNameValuePairs('LiveText__Conversation_Header__c', session.Id);
        TestDataFactory.setFieldNameValuePairs('LiveText__First_Name__c', 'Tony');
        TestDataFactory.setFieldNameValuePairs('LiveText__Last_Name__c', 'Stark');
        TestDataFactory.setFieldNameValuePairs('LiveText__Originating_Number__c', TEST_FB_ID);
        TestDataFactory.setFieldNameValuePairs('LiveText__Message__c', 'hello');
        TestDataFactory.setFieldNameValuePairs('LiveText__Status__c', '');
        LiveText__SMS_Text__c smsTextData = (LiveText__SMS_Text__c) TestDataFactory.createSObject('LiveText__SMS_Text__c');
        TestDataFactory.resetFieldNameValuePairs();

        smsTextData.put('LiveText__Conversation_Header__c', session.Id);
        update smsTextData;

        Test.stopTest();

        Account acc = [SELECT Id, FacebookId__pc FROM Account];
        System.assertEquals(TEST_FB_ID, acc.FacebookId__pc);

        LiveText__Conversation_Header__c updatedSession = [SELECT Id, LiveText__Account__c FROM LiveText__Conversation_Header__c WHERE Id = :session.Id];
        System.assertEquals(acc.Id, updatedSession.LiveText__Account__c);
    }

    @isTest
    static void testFirstSMSMessageWithoutAccount() { // first sms message from customer and there is no person account in sf yet
        String smsChannelId = [SELECT Id FROM LiveText__LiveText_Number__c WHERE LiveText__Channel_Type__c = 'Text' LIMIT 1].Id;

        TestDataFactory.setInsertOBjects(true);

        //LiveText__Conversation_Header__c
        TestDataFactory.setFieldNameValuePairs('LiveText__Support_Number__c', smsChannelId);
        TestDataFactory.setFieldNameValuePairs('LiveText__Originating_Number__c', TEST_PHONE_NUMBER);
        TestDataFactory.setFieldNameValuePairs('LiveText__Status__c', 'New');
        LiveText__Conversation_Header__c session = (LiveText__Conversation_Header__c) TestDataFactory.createSObject('LiveText__Conversation_Header__c');
        TestDataFactory.resetFieldNameValuePairs();

        System.assertEquals(0, [SELECT Id, FacebookId__pc FROM Account].size());
        System.assertEquals(null, [SELECT Id, LiveText__Account__c FROM LiveText__Conversation_Header__c WHERE Id = :session.Id].LiveText__Account__c);

        Test.startTest();

        SendMessageJob.doChainJob = false;

        Test.setMock(HttpCalloutMock.class, new MockHttpResponseGenerator(GET_CUSTOMER_SERVICE_DATA_RESPONSE));

        //LiveText__SMS_Text__c
        TestDataFactory.setFieldNameValuePairs('LiveText__Conversation_Header__c', session.Id);
        TestDataFactory.setFieldNameValuePairs('LiveText__First_Name__c', 'Tony');
        TestDataFactory.setFieldNameValuePairs('LiveText__Last_Name__c', 'Stark');
        TestDataFactory.setFieldNameValuePairs('LiveText__Originating_Number__c', TEST_PHONE_NUMBER);
        TestDataFactory.setFieldNameValuePairs('LiveText__Message__c', 'hello');
        TestDataFactory.setFieldNameValuePairs('LiveText__Status__c', '');
        LiveText__SMS_Text__c smsTextData = (LiveText__SMS_Text__c) TestDataFactory.createSObject('LiveText__SMS_Text__c');
        TestDataFactory.resetFieldNameValuePairs();

        Test.stopTest();

        Account acc = [SELECT Id, Phone,CustomerRowId__pc FROM Account];
        System.assertEquals(TEST_PHONE_NUMBER, acc.Phone);

        LiveText__Conversation_Header__c updatedSession = [SELECT Id, LiveText__Account__c FROM LiveText__Conversation_Header__c WHERE Id = :session.Id];
        System.assertEquals(acc.Id, updatedSession.LiveText__Account__c);
        System.assertNotEquals(null,acc.CustomerRowId__pc);
    }

    @isTest
    static void testFirstFBMessageWithAccount() { // first facebook message from customer and there is person account in sf
        String fbChannelId = [SELECT Id FROM LiveText__LiveText_Number__c WHERE LiveText__Channel_Type__c = 'Facebook' LIMIT 1].Id;

        TestDataFactory.setInsertOBjects(true);

        //Account
        TestDataFactory.setFieldNameValuePairs('RecordTypeId', 'LiveMessage');
        TestDataFactory.setFieldNameValuePairs('FirstName', 'Tony');
        TestDataFactory.setFieldNameValuePairs('LastName', 'Stark');
        TestDataFactory.setFieldNameValuePairs('FacebookId__pc', TEST_FB_ID);
        TestDataFactory.setFieldNameValuePairs('CustomerId__pc', TEST_CUSTOMER_NUMBER);
        Account testAccount = (Account) TestDataFactory.createSObject('Account');
        TestDataFactory.resetFieldNameValuePairs();

        Account acc = [SELECT Id, PersonContactId, FirstName, LastName, FacebookId__pc FROM Account WHERE Id = :testAccount.Id];

        //LiveText__Conversation_Header__c
        TestDataFactory.setFieldNameValuePairs('LiveText__Support_Number__c', fbChannelId);
        TestDataFactory.setFieldNameValuePairs('LiveText__Originating_Number__c', TEST_FB_ID);
        TestDataFactory.setFieldNameValuePairs('LiveText__Status__c', 'New');
        LiveText__Conversation_Header__c session = (LiveText__Conversation_Header__c) TestDataFactory.createSObject('LiveText__Conversation_Header__c');
        TestDataFactory.resetFieldNameValuePairs();

        System.assertEquals(1, [SELECT Id, FacebookId__pc FROM Account].size());
        System.assertEquals(null, [SELECT Id, LiveText__Account__c FROM LiveText__Conversation_Header__c WHERE Id = :session.Id].LiveText__Account__c);

        Test.startTest();

        SendMessageJob.doChainJob = false;

        //LiveText__SMS_Text__c
        TestDataFactory.setFieldNameValuePairs('LiveText__Conversation_Header__c', session.Id);
        TestDataFactory.setFieldNameValuePairs('LiveText__First_Name__c', acc.FirstName);
        TestDataFactory.setFieldNameValuePairs('LiveText__Last_Name__c', acc.LastName);
        TestDataFactory.setFieldNameValuePairs('LiveText__Originating_Number__c', acc.FacebookId__pc);
        TestDataFactory.setFieldNameValuePairs('LiveText__Message__c', 'hello');
        TestDataFactory.setFieldNameValuePairs('LiveText__Status__c', '');
        LiveText__SMS_Text__c smsTextData = (LiveText__SMS_Text__c) TestDataFactory.createSObject('LiveText__SMS_Text__c');
        TestDataFactory.resetFieldNameValuePairs();

        Test.stopTest();

        LiveText__Conversation_Header__c updatedSession = [SELECT Id, LiveText__Account__c FROM LiveText__Conversation_Header__c WHERE Id = :session.Id];
        System.assertEquals(acc.Id, updatedSession.LiveText__Account__c);
    }

    @isTest
    static void testCheckCustomerNumberRetry() {
        String fbChannelId = [SELECT Id FROM LiveText__LiveText_Number__c WHERE LiveText__Channel_Type__c = 'Facebook' LIMIT 1].Id;

        TestDataFactory.setInsertOBjects(true);

        //Account
        TestDataFactory.setFieldNameValuePairs('RecordTypeId', 'LiveMessage');
        TestDataFactory.setFieldNameValuePairs('FirstName', 'Tony');
        TestDataFactory.setFieldNameValuePairs('LastName', 'Stark');
        TestDataFactory.setFieldNameValuePairs('FacebookId__pc', TEST_FB_ID);
        TestDataFactory.setFieldNameValuePairs('Retry_Number_Customers__pc', '0');
        TestDataFactory.setFieldNameValuePairs('Retry_Number_Customers_Time__pc', String.valueOf(Datetime.now().addMinutes(-20)));
        Account testAccount = (Account) TestDataFactory.createSObject('Account');
        TestDataFactory.resetFieldNameValuePairs();

        Account acc = [SELECT Id, PersonContactId, FirstName, LastName, FacebookId__pc, Retry_Number_Customers__pc FROM Account WHERE Id = :testAccount.Id];

        //LiveText__Conversation_Header__c
        TestDataFactory.setFieldNameValuePairs('LiveText__Support_Number__c', fbChannelId);
        TestDataFactory.setFieldNameValuePairs('LiveText__Originating_Number__c', TEST_FB_ID);
        TestDataFactory.setFieldNameValuePairs('LiveText__Status__c', 'New');
        TestDataFactory.setFieldNameValuePairs('LiveText__Account__c', testAccount.Id);
        LiveText__Conversation_Header__c session = (LiveText__Conversation_Header__c) TestDataFactory.createSObject('LiveText__Conversation_Header__c');
        TestDataFactory.resetFieldNameValuePairs();

        System.assertNotEquals(null, acc);
        System.assertEquals(0, acc.Retry_Number_Customers__pc);

        Test.startTest();

        SendMessageJob.doChainJob = false;

        Test.setMock(HttpCalloutMock.class, new MockHttpResponseGenerator(GET_CUSTOMER_SERVICE_DATA_RESPONSE_NO_FOUND));

        //LiveText__SMS_Text__c
        TestDataFactory.setFieldNameValuePairs('LiveText__Conversation_Header__c', session.Id);
        TestDataFactory.setFieldNameValuePairs('LiveText__First_Name__c', acc.FirstName);
        TestDataFactory.setFieldNameValuePairs('LiveText__Last_Name__c', acc.LastName);
        TestDataFactory.setFieldNameValuePairs('LiveText__Originating_Number__c', acc.FacebookId__pc);
        TestDataFactory.setFieldNameValuePairs('LiveText__Message__c', TEST_CUSTOMER_NUMBER);
        TestDataFactory.setFieldNameValuePairs('LiveText__Status__c', '');
        LiveText__SMS_Text__c smsTextData = (LiveText__SMS_Text__c) TestDataFactory.createSObject('LiveText__SMS_Text__c');
        TestDataFactory.resetFieldNameValuePairs();

        Test.stopTest();

        Account accRetry = [SELECT Id, Retry_Number_Customers__pc FROM Account WHERE Id = :testAccount.Id];
        System.assertEquals(1, accRetry.Retry_Number_Customers__pc);
    }

    @isTest
    static void testCheckCustomerNumber() {
        String fbChannelId = [SELECT Id FROM LiveText__LiveText_Number__c WHERE LiveText__Channel_Type__c = 'Facebook' LIMIT 1].Id;

        TestDataFactory.setInsertOBjects(true);

        //Account
        TestDataFactory.setFieldNameValuePairs('RecordTypeId', 'LiveMessage');
        TestDataFactory.setFieldNameValuePairs('FirstName', 'Tony');
        TestDataFactory.setFieldNameValuePairs('LastName', 'Stark');
        TestDataFactory.setFieldNameValuePairs('FacebookId__pc', TEST_FB_ID);
        TestDataFactory.setFieldNameValuePairs('Retry_Number_Customers__pc', '0');
        TestDataFactory.setFieldNameValuePairs('Retry_Number_Customers_Time__pc', String.valueOf(Datetime.now().addMinutes(-20)));
        TestDataFactory.setFieldNameValuePairs('FAA_Failed__c', 'false');
        Account testAccount = (Account) TestDataFactory.createSObject('Account');
        TestDataFactory.resetFieldNameValuePairs();

        Account acc = [SELECT Id, PersonContactId, FirstName, LastName, FacebookId__pc, Retry_Number_Customers__pc FROM Account WHERE Id = :testAccount.Id];

        //LiveText__Conversation_Header__c
        TestDataFactory.setFieldNameValuePairs('LiveText__Support_Number__c', fbChannelId);
        TestDataFactory.setFieldNameValuePairs('LiveText__Originating_Number__c', TEST_FB_ID);
        TestDataFactory.setFieldNameValuePairs('LiveText__Status__c', 'New');
        TestDataFactory.setFieldNameValuePairs('LiveText__Account__c', testAccount.Id);
        LiveText__Conversation_Header__c session = (LiveText__Conversation_Header__c) TestDataFactory.createSObject('LiveText__Conversation_Header__c');
        TestDataFactory.resetFieldNameValuePairs();

        System.assertNotEquals(null, acc);
        System.assertEquals(0, acc.Retry_Number_Customers__pc);

        Test.startTest();

        SendMessageJob.doChainJob = false;

        Test.setMock(HttpCalloutMock.class, new MockHttpResponseGenerator(GET_CUSTOMER_SERVICE_DATA_RESPONSE));

        //LiveText__SMS_Text__c
        TestDataFactory.setFieldNameValuePairs('LiveText__Conversation_Header__c', session.Id);
        TestDataFactory.setFieldNameValuePairs('LiveText__First_Name__c', acc.FirstName);
        TestDataFactory.setFieldNameValuePairs('LiveText__Last_Name__c', acc.LastName);
        TestDataFactory.setFieldNameValuePairs('LiveText__Originating_Number__c', acc.FacebookId__pc);
        TestDataFactory.setFieldNameValuePairs('LiveText__Message__c', TEST_CUSTOMER_NUMBER);
        TestDataFactory.setFieldNameValuePairs('LiveText__Status__c', '');
        LiveText__SMS_Text__c smsTextData = (LiveText__SMS_Text__c) TestDataFactory.createSObject('LiveText__SMS_Text__c');
        TestDataFactory.resetFieldNameValuePairs();

        Test.stopTest();

        Account accRetry = [SELECT Id, FAA_Failed__c, Retry_Number_Customers__pc FROM Account WHERE Id = :testAccount.Id];
        System.assertEquals(0, accRetry.Retry_Number_Customers__pc);
        System.assertEquals(false, accRetry.FAA_Failed__c);
    }

    @isTest
    static void testCheckCustomerNumberFAAFailed() {
        String fbChannelId = [SELECT Id FROM LiveText__LiveText_Number__c WHERE LiveText__Channel_Type__c = 'Facebook' LIMIT 1].Id;

        TestDataFactory.setInsertOBjects(true);

        //Account
        TestDataFactory.setFieldNameValuePairs('RecordTypeId', 'LiveMessage');
        TestDataFactory.setFieldNameValuePairs('FirstName', 'Tony');
        TestDataFactory.setFieldNameValuePairs('LastName', 'Stark');
        TestDataFactory.setFieldNameValuePairs('FacebookId__pc', TEST_FB_ID);
        TestDataFactory.setFieldNameValuePairs('Retry_Number_Customers__pc', '0');
        TestDataFactory.setFieldNameValuePairs('Retry_Number_Customers_Time__pc', String.valueOf(Datetime.now().addMinutes(-20)));
        TestDataFactory.setFieldNameValuePairs('FAA_Failed__c', 'false');
        Account testAccount = (Account) TestDataFactory.createSObject('Account');
        TestDataFactory.resetFieldNameValuePairs();

        Account acc = [SELECT Id, PersonContactId, FirstName, LastName, FacebookId__pc, Retry_Number_Customers__pc FROM Account WHERE Id = :testAccount.Id];

        //LiveText__Conversation_Header__c
        TestDataFactory.setFieldNameValuePairs('LiveText__Support_Number__c', fbChannelId);
        TestDataFactory.setFieldNameValuePairs('LiveText__Originating_Number__c', TEST_FB_ID);
        TestDataFactory.setFieldNameValuePairs('LiveText__Status__c', 'New');
        TestDataFactory.setFieldNameValuePairs('LiveText__Account__c', testAccount.Id);
        LiveText__Conversation_Header__c session = (LiveText__Conversation_Header__c) TestDataFactory.createSObject('LiveText__Conversation_Header__c');
        TestDataFactory.resetFieldNameValuePairs();

        System.assertNotEquals(null, acc);
        System.assertEquals(0, acc.Retry_Number_Customers__pc);

        Test.startTest();

        SendMessageJob.doChainJob = false;

        Test.setMock(HttpCalloutMock.class, new MockHttpResponseGenerator('failed', 503));

        //LiveText__SMS_Text__c
        TestDataFactory.setFieldNameValuePairs('LiveText__Conversation_Header__c', session.Id);
        TestDataFactory.setFieldNameValuePairs('LiveText__First_Name__c', acc.FirstName);
        TestDataFactory.setFieldNameValuePairs('LiveText__Last_Name__c', acc.LastName);
        TestDataFactory.setFieldNameValuePairs('LiveText__Originating_Number__c', acc.FacebookId__pc);
        TestDataFactory.setFieldNameValuePairs('LiveText__Message__c', TEST_CUSTOMER_NUMBER);
        TestDataFactory.setFieldNameValuePairs('LiveText__Status__c', '');
        LiveText__SMS_Text__c smsTextData = (LiveText__SMS_Text__c) TestDataFactory.createSObject('LiveText__SMS_Text__c');
        TestDataFactory.resetFieldNameValuePairs();

        Test.stopTest();

        Account accRetry = [SELECT Id, FAA_Failed__c, Retry_Number_Customers__pc FROM Account WHERE Id = :testAccount.Id];
        System.assertEquals(0, accRetry.Retry_Number_Customers__pc);
        System.assertEquals(true, accRetry.FAA_Failed__c);
    }

    @isTest
    static void testSelectOptionRetry() {
        String fbChannelId = [SELECT Id FROM LiveText__LiveText_Number__c WHERE LiveText__Channel_Type__c = 'Facebook' LIMIT 1].Id;

        TestDataFactory.setInsertOBjects(true);

        //Account
        TestDataFactory.setFieldNameValuePairs('RecordTypeId', 'LiveMessage');
        TestDataFactory.setFieldNameValuePairs('FirstName', 'Tony');
        TestDataFactory.setFieldNameValuePairs('LastName', 'Stark');
        TestDataFactory.setFieldNameValuePairs('FacebookId__pc', TEST_FB_ID);
        TestDataFactory.setFieldNameValuePairs('Retry_Number_Options__pc', '0');
        TestDataFactory.setFieldNameValuePairs('Retry_Number_Options_Time__pc', String.valueOf(Datetime.now().addMinutes(-20)));
        TestDataFactory.setFieldNameValuePairs('CustomerId__pc', TEST_CUSTOMER_NUMBER);
        Account testAccount = (Account) TestDataFactory.createSObject('Account');
        TestDataFactory.resetFieldNameValuePairs();

        Account acc = [SELECT Id, PersonContactId, FirstName, LastName, FacebookId__pc, Retry_Number_Options__pc FROM Account WHERE Id = :testAccount.Id];

        //LiveText__Conversation_Header__c
        TestDataFactory.setFieldNameValuePairs('LiveText__Support_Number__c', fbChannelId);
        TestDataFactory.setFieldNameValuePairs('LiveText__Originating_Number__c', TEST_FB_ID);
        TestDataFactory.setFieldNameValuePairs('LiveText__Status__c', 'New');
        TestDataFactory.setFieldNameValuePairs('LiveText__Account__c', testAccount.Id);
        LiveText__Conversation_Header__c session = (LiveText__Conversation_Header__c) TestDataFactory.createSObject('LiveText__Conversation_Header__c');
        TestDataFactory.resetFieldNameValuePairs();

        System.assertNotEquals(null, acc);
        System.assertEquals(0, acc.Retry_Number_Options__pc);

        Test.startTest();

        SendMessageJob.doChainJob = false;

        //LiveText__SMS_Text__c
        TestDataFactory.setFieldNameValuePairs('LiveText__Conversation_Header__c', session.Id);
        TestDataFactory.setFieldNameValuePairs('LiveText__First_Name__c', acc.FirstName);
        TestDataFactory.setFieldNameValuePairs('LiveText__Last_Name__c', acc.LastName);
        TestDataFactory.setFieldNameValuePairs('LiveText__Originating_Number__c', acc.FacebookId__pc);
        TestDataFactory.setFieldNameValuePairs('LiveText__Message__c', 'incorrect option');
        TestDataFactory.setFieldNameValuePairs('LiveText__Status__c', '');
        LiveText__SMS_Text__c smsTextData = (LiveText__SMS_Text__c) TestDataFactory.createSObject('LiveText__SMS_Text__c');
        TestDataFactory.resetFieldNameValuePairs();

        Test.stopTest();

        Account accRetry = [SELECT Id, Retry_Number_Options__pc FROM Account WHERE Id = :testAccount.Id];
        System.assertEquals(1, accRetry.Retry_Number_Options__pc);
    }

    @isTest
    static void testSelectOption() {
        String fbChannelId = [SELECT Id FROM LiveText__LiveText_Number__c WHERE LiveText__Channel_Type__c = 'Facebook' LIMIT 1].Id;

        TestDataFactory.setInsertOBjects(true);

        //Account
        TestDataFactory.setFieldNameValuePairs('RecordTypeId', 'LiveMessage');
        TestDataFactory.setFieldNameValuePairs('FirstName', 'Tony');
        TestDataFactory.setFieldNameValuePairs('LastName', 'Stark');
        TestDataFactory.setFieldNameValuePairs('FacebookId__pc', TEST_FB_ID);
        TestDataFactory.setFieldNameValuePairs('Retry_Number_Options__pc', '0');
        TestDataFactory.setFieldNameValuePairs('Retry_Number_Options_Time__pc', String.valueOf(Datetime.now().addMinutes(-20)));
        TestDataFactory.setFieldNameValuePairs('CustomerId__pc', TEST_CUSTOMER_NUMBER);
        Account testAccount = (Account) TestDataFactory.createSObject('Account');
        TestDataFactory.resetFieldNameValuePairs();

        Account acc = [SELECT Id, PersonContactId, FirstName, LastName, FacebookId__pc, Retry_Number_Options__pc FROM Account WHERE Id = :testAccount.Id];

        //LiveText__Conversation_Header__c
        TestDataFactory.setFieldNameValuePairs('LiveText__Support_Number__c', fbChannelId);
        TestDataFactory.setFieldNameValuePairs('LiveText__Originating_Number__c', TEST_FB_ID);
        TestDataFactory.setFieldNameValuePairs('LiveText__Status__c', 'New');
        TestDataFactory.setFieldNameValuePairs('LiveText__Account__c', testAccount.Id);
        LiveText__Conversation_Header__c session = (LiveText__Conversation_Header__c) TestDataFactory.createSObject('LiveText__Conversation_Header__c');
        TestDataFactory.resetFieldNameValuePairs();

        System.assertNotEquals(null, acc);
        System.assertEquals(0, acc.Retry_Number_Options__pc);

        Test.startTest();

        SendMessageJob.doChainJob = false;

        Test.setMock(HttpCalloutMock.class, new MockHttpResponseGenerator(GET_CUSTOMER_DATA_RESPONSE));

        //LiveText__SMS_Text__c
        TestDataFactory.setFieldNameValuePairs('LiveText__Conversation_Header__c', session.Id);
        TestDataFactory.setFieldNameValuePairs('LiveText__First_Name__c', acc.FirstName);
        TestDataFactory.setFieldNameValuePairs('LiveText__Last_Name__c', acc.LastName);
        TestDataFactory.setFieldNameValuePairs('LiveText__Originating_Number__c', acc.FacebookId__pc);
        TestDataFactory.setFieldNameValuePairs('LiveText__Message__c', '1');
        TestDataFactory.setFieldNameValuePairs('LiveText__Status__c', '');
        LiveText__SMS_Text__c smsTextData = (LiveText__SMS_Text__c) TestDataFactory.createSObject('LiveText__SMS_Text__c');
        TestDataFactory.resetFieldNameValuePairs();

        Test.stopTest();

        Account accRetry = [SELECT Id, Retry_Number_Options__pc FROM Account WHERE Id = :testAccount.Id];
        System.assertEquals(0, accRetry.Retry_Number_Options__pc);
        System.assertEquals(1, [SELECT Id FROM Case WHERE AccountId = :testAccount.Id].size());
        System.assertEquals(false, [SELECT Id, Is_Retention__c FROM Case WHERE AccountId = :testAccount.Id].Is_Retention__c);
    }

    @isTest
    static void testSelectOptionRetention() {
        String fbChannelId = [SELECT Id FROM LiveText__LiveText_Number__c WHERE LiveText__Channel_Type__c = 'Facebook' LIMIT 1].Id;

        TestDataFactory.setInsertOBjects(true);

        //Account
        TestDataFactory.setFieldNameValuePairs('RecordTypeId', 'LiveMessage');
        TestDataFactory.setFieldNameValuePairs('FirstName', 'Tony');
        TestDataFactory.setFieldNameValuePairs('LastName', 'Stark');
        TestDataFactory.setFieldNameValuePairs('FacebookId__pc', TEST_FB_ID);
        TestDataFactory.setFieldNameValuePairs('Retry_Number_Options__pc', '0');
        TestDataFactory.setFieldNameValuePairs('Retry_Number_Options_Time__pc', String.valueOf(Datetime.now().addMinutes(-20)));
        TestDataFactory.setFieldNameValuePairs('CustomerId__pc', TEST_CUSTOMER_NUMBER);
        Account testAccount = (Account) TestDataFactory.createSObject('Account');
        TestDataFactory.resetFieldNameValuePairs();

        Account acc = [SELECT Id, PersonContactId, FirstName, LastName, FacebookId__pc, Retry_Number_Options__pc FROM Account WHERE Id = :testAccount.Id];

        //LiveText__Conversation_Header__c
        TestDataFactory.setFieldNameValuePairs('LiveText__Support_Number__c', fbChannelId);
        TestDataFactory.setFieldNameValuePairs('LiveText__Originating_Number__c', TEST_FB_ID);
        TestDataFactory.setFieldNameValuePairs('LiveText__Status__c', 'New');
        TestDataFactory.setFieldNameValuePairs('LiveText__Account__c', testAccount.Id);
        LiveText__Conversation_Header__c session = (LiveText__Conversation_Header__c) TestDataFactory.createSObject('LiveText__Conversation_Header__c');
        TestDataFactory.resetFieldNameValuePairs();

        System.assertNotEquals(null, acc);
        System.assertEquals(0, acc.Retry_Number_Options__pc);

        Test.startTest();

        SendMessageJob.doChainJob = false;

        Test.setMock(HttpCalloutMock.class, new MockHttpResponseGenerator(GET_CUSTOMER_DATA_RESPONSE_RETENTION));

        //LiveText__SMS_Text__c
        TestDataFactory.setFieldNameValuePairs('LiveText__Conversation_Header__c', session.Id);
        TestDataFactory.setFieldNameValuePairs('LiveText__First_Name__c', acc.FirstName);
        TestDataFactory.setFieldNameValuePairs('LiveText__Last_Name__c', acc.LastName);
        TestDataFactory.setFieldNameValuePairs('LiveText__Originating_Number__c', acc.FacebookId__pc);
        TestDataFactory.setFieldNameValuePairs('LiveText__Message__c', '1');
        TestDataFactory.setFieldNameValuePairs('LiveText__Status__c', '');
        LiveText__SMS_Text__c smsTextData = (LiveText__SMS_Text__c) TestDataFactory.createSObject('LiveText__SMS_Text__c');
        TestDataFactory.resetFieldNameValuePairs();

        Test.stopTest();

        Account accRetry = [SELECT Id, Retry_Number_Options__pc FROM Account WHERE Id = :testAccount.Id];
        System.assertEquals(0, accRetry.Retry_Number_Options__pc);
        System.assertEquals(1, [SELECT Id FROM Case WHERE AccountId = :testAccount.Id].size());
        System.assertEquals(true, [SELECT Id, Is_Retention__c FROM Case WHERE AccountId = :testAccount.Id].Is_Retention__c);
    }

    @IsTest
    static void testUpdateLastMessageTimestamps() {
        String fbChannelId = [SELECT Id FROM LiveText__LiveText_Number__c WHERE LiveText__Channel_Type__c = 'Facebook' LIMIT 1].Id;

        //Account
        TestDataFactory.setFieldNameValuePairs('RecordTypeId', 'LiveMessage');
        TestDataFactory.setFieldNameValuePairs('FirstName', 'Tony');
        TestDataFactory.setFieldNameValuePairs('LastName', 'Stark');
        TestDataFactory.setFieldNameValuePairs('FacebookId__pc', TEST_FB_ID);
        TestDataFactory.setFieldNameValuePairs('CustomerId__pc', TEST_CUSTOMER_NUMBER);

        Account testAccount = (Account) TestDataFactory.createSObject('Account');
        insert testAccount;

        TestDataFactory.resetFieldNameValuePairs();

        Account acc = [SELECT Id, PersonContactId, FirstName, LastName, FacebookId__pc FROM Account WHERE Id = :testAccount.Id];

        //LiveText__Conversation_Header__c
        TestDataFactory.setFieldNameValuePairs('LiveText__Support_Number__c', fbChannelId);
        TestDataFactory.setFieldNameValuePairs('LiveText__Originating_Number__c', TEST_FB_ID);
        TestDataFactory.setFieldNameValuePairs('LiveText__Status__c', 'Active');

        LiveText__Conversation_Header__c session = (LiveText__Conversation_Header__c) TestDataFactory.createSObject('LiveText__Conversation_Header__c');

        /* need to null these datetime values as the TestDataFactory sets a default value */
        session.LastMessageSent__c = null;
        session.LastMessageReceived__c = null;
        session.AgentReplyPendingSince__c = null;

        insert session;

        TestDataFactory.resetFieldNameValuePairs();

        Test.startTest();

        SendMessageJob.doChainJob = false;

        TestDataFactory.setFieldNameValuePairs('LiveText__Conversation_Header__c', session.Id);
        TestDataFactory.setFieldNameValuePairs('LiveText__First_Name__c', acc.FirstName);
        TestDataFactory.setFieldNameValuePairs('LiveText__Last_Name__c', acc.LastName);
        TestDataFactory.setFieldNameValuePairs('LiveText__Originating_Number__c', acc.FacebookId__pc);
        TestDataFactory.setFieldNameValuePairs('LiveText__Message__c', 'hello');
        TestDataFactory.setFieldNameValuePairs('LiveText__Status__c', '');
        TestDataFactory.setFieldNameValuePairs('LiveText__Source__c', 'LiveText');
        TestDataFactory.setFieldNameValuePairs('LiveText__Sent_To_Customer__c', 'false');

        insert TestDataFactory.createSObject('LiveText__SMS_Text__c');

        TestDataFactory.resetFieldNameValuePairs();

        LiveText__Conversation_Header__c updatedSession = [
            SELECT Id, LastMessageSent__c, LastMessageReceived__c, AgentReplyPendingSince__c
            FROM LiveText__Conversation_Header__c
            WHERE Id = :session.Id
        ];

        System.debug(updatedSession);

        Long now = Datetime.now().getTime();

        System.assertEquals(null, updatedSession.LastMessageSent__c);
        System.assertNotEquals(null, updatedSession.LastMessageReceived__c);
        System.assertNotEquals(null, updatedSession.AgentReplyPendingSince__c);
        System.assert(1000 > updatedSession.LastMessageReceived__c.getTime() - now);
        System.assert(1000 > updatedSession.AgentReplyPendingSince__c.getTime() - now);

        TestDataFactory.setFieldNameValuePairs('LiveText__Conversation_Header__c', session.Id);
        TestDataFactory.setFieldNameValuePairs('LiveText__First_Name__c', acc.FirstName);
        TestDataFactory.setFieldNameValuePairs('LiveText__Last_Name__c', acc.LastName);
        TestDataFactory.setFieldNameValuePairs('LiveText__Originating_Number__c', acc.FacebookId__pc);
        TestDataFactory.setFieldNameValuePairs('LiveText__Message__c', 'hello back');
        TestDataFactory.setFieldNameValuePairs('LiveText__Status__c', '');
        TestDataFactory.setFieldNameValuePairs('LiveText__Source__c', 'Salesforce');
        TestDataFactory.setFieldNameValuePairs('LiveText__Sent_To_Customer__c', 'true');

        insert TestDataFactory.createSObject('LiveText__SMS_Text__c');

        TestDataFactory.resetFieldNameValuePairs();

        updatedSession = [
            SELECT Id, LastMessageSent__c, LastMessageReceived__c, AgentReplyPendingSince__c
            FROM LiveText__Conversation_Header__c
            WHERE Id = :session.Id
        ];

        System.debug(updatedSession);

        System.assertNotEquals(null, updatedSession.LastMessageSent__c);
        System.assertNotEquals(null, updatedSession.LastMessageReceived__c);
        System.assertEquals(null, updatedSession.AgentReplyPendingSince__c);
        System.assert(1000 > updatedSession.LastMessageSent__c.getTime() - now);
        System.assert(1000 > updatedSession.LastMessageReceived__c.getTime() - now);

        Test.stopTest();
    }
}