/*------------------------------------------------------------
Author: Pavel Usoltsev
Company: Salesforce
Description: A test class created to validate class ClearRetryCountContacts
             Tests executed:
             1 - testScheduledJob()
             Launch the scheduler, test if it is scheduled.
             Make SOQL query, which return result of values.
             Compare received result with expected
             2 - testClearContactRetry()
             Test the clear logic of retry count for a  contact
             Make SOQL query, which return result of values.
             Compare received result with expected


History
8/10/18    Pavel Usoltsev    Initial Version.
------------------------------------------------------------*/
@isTest
private class ClearRetryCountContacts_Test {

    @isTest
    private static void testScheduledJob() {

        Test.startTest();

        String jobId = System.schedule('RetryCountClearJob', '0 0 1 * * ?', new ClearRetryCountContacts());

        CronTrigger ct = [
                SELECT Id, CronExpression, TimesTriggered,
                        NextFireTime
                FROM CronTrigger
                WHERE id = :jobId
        ];

        System.assertEquals('0 0 1 * * ?',
                ct.CronExpression);

        System.assertEquals('0 0 1 * * ?',
                ct.CronExpression);

        System.assertEquals(0, ct.TimesTriggered);

        Test.stopTest();

    }

    @isTest
    private static void testClearContactRetry() {
        TestDataFactory.setInsertOBjects(true);

        Test.startTest();
//        Contact cont = new Contact(LastName = 'Test', Retry_Number_Customers__c = 2, Retry_Number_Options__c = 2);
//
//        insert cont;
        //Account
        TestDataFactory.setFieldNameValuePairs('RecordTypeId', 'LiveMessage');
        TestDataFactory.setFieldNameValuePairs('LastName', 'Test');
        TestDataFactory.setFieldNameValuePairs('Retry_Number_Customers__pc', '2');
        TestDataFactory.setFieldNameValuePairs('Retry_Number_Options__pc', '2');
        Account testAccount = (Account) TestDataFactory.createSObject('Account');
        TestDataFactory.resetFieldNameValuePairs();

        ClearRetryCountContacts.clearContactRetryFields();

        Contact contact = [SELECT Retry_Number_Customers__c, Retry_Number_Options__c FROM Contact LIMIT 1];

        System.assertEquals(0, contact.Retry_Number_Customers__c);
        System.assertEquals(0, contact.Retry_Number_Options__c);
        Test.stopTest();
    }

}