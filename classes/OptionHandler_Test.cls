/*------------------------------------------------------------------------
Author:      Pavel Usoltsev
Company:     Salesforce
Description: A test class created to validate class MessageLiveHandler
             Tests executed:
             1 - checkIfOptionNumberIsAssigned_Test()
             Create LiveText__LiveText_Number__c records with different field values
             Inserted this values
             Make SOQL query, which return result List<LiveText__LiveText_Number__c>
             Compare received result with expected
             Create MessageLive__c records with different field values
             Insert this values
             Made SOQL query, which return result List<MessageLive__c>
             Compare received result with expected
             Create Option__c records with different field values
             Insert this values
             Updated some values
             Make SOQL query, which return result  List<Option__c>
             Compare received result with expected
History
7/29/18    Pavel Usoltsev   Initial Version
----------------------------------------------------------------------------*/
@isTest
private class OptionHandler_Test {

    @testSetup
    static void setup(){
        LiveText__LiveText_Number__c testLiveText           = new LiveText__LiveText_Number__c();
        testLiveText.LiveText__Auto_Response_Message__c     = 'hello from SMS';
        testLiveText.LiveText__Number__c                    = '+491771783610';
        insert testLiveText;

        LiveText__LiveText_Number__c testLiveText2          = new LiveText__LiveText_Number__c();
        testLiveText2.LiveText__Auto_Response_Message__c    = 'testString';
        testLiveText2.LiveText__Number__c                   = '222222';
        insert testLiveText2;

        List<LiveText__LiveText_Number__c> selectLiveText  = [select Id, LiveText__Auto_Response_Message__c, LiveText__Number__c  from LiveText__LiveText_Number__c];
        System.assertEquals(2, selectLiveText.size(), 'Results query returned no results');

        MessageLive__c testMessageLive                      = new MessageLive__c();
        testMessageLive.LiveMessageNumber__c                = testLiveText.Id;
        testMessageLive.Active__c                           = true;
        insert testMessageLive;

        MessageLive__c testMessageLive2                     = new MessageLive__c();
        testMessageLive2.LiveMessageNumber__c               = testLiveText2.Id;
        testMessageLive2.Active__c = false;
        insert testMessageLive2;

        List<MessageLive__c> selectMessageLive = [select Id, Active__c  from MessageLive__c];
        System.assertEquals(2, selectMessageLive.size(), 'Results query returned no results');

        Option__c testOption                                = new Option__c();
        testOption.Name                                     = 'Everything is working';
        testOption.Option_No__c                             = '2';
        testOption.MessageLive__c                           = testMessageLive.Id;

        insert testOption;

        Option__c testOption2                               = new Option__c();
        testOption2.Name                                    = 'Nothing is working';
        testOption2.Option_No__c                            = '1';
        testOption2.MessageLive__c                          = testMessageLive2.Id;

        insert testOption2;

        List<Option__c> selectOption = [select Id, Name, Option_No__c, MessageLive__c  from Option__c];
        System.assertEquals(2, selectOption.size(), 'Results query returned no results');
        System.debug('selectOption>>>>' + selectOption);

    }

    @isTest
    private static  void checkIfOptionNumberIsAssigned_Test(){

        MessageLive__c mLive = [SELECT Id FROM MessageLive__c][0];

        Option__c testOption3           = new Option__c();
        testOption3.Name                = 'Nothing is working';
        testOption3.Option_No__c        = '1';
        testOption3.MessageLive__c      = mLive.Id;

        insert testOption3;

        try{
            Option__c testOption4       = new Option__c();
            testOption4.Name            = 'Nothing is working';
            testOption4.Option_No__c    = '1';
            testOption4.MessageLive__c  = mLive.Id;

            insert testOption4;

        }catch(DmlException e){
            system.assertEquals('Insert failed. First exception on row 0; first error: FIELD_CUSTOM_VALIDATION_EXCEPTION, The option with this number already exist!: []', e.getMessage());
        }

        testOption3.Name                = 'Everything is working';
        testOption3.Option_No__c        = '1';

        update testOption3;
        delete testOption3;

        List<Option__c> selectOptions  = [select Id from Option__c];
        System.assertEquals(2, selectOptions.size(), 'Results query returned no results');
    }
    
}