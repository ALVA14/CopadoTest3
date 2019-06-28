/*------------------------------------------------------------
Author: Pavel Usoltsev
Company: Salesforce
Description: Clear retry the count of incorrect retry attempts for the customers every day
Inputs:
Test Class:  ClearRetryCountContacts_Test

History
8/10/18    Pavel Usoltsev    Initial Version.
------------------------------------------------------------*/
global class ClearRetryCountContacts implements Schedulable {
    global void execute(SchedulableContext SC) {
        clearContactRetryFields();
    }

    /*------------------------------------------------------------
    Author: Pavel Usoltsev
    Company: Salesforce
    Description: Schedule the everyday's scheduler.
    Inputs:      void
    Returns:

    History
    8/10/18    Pavel Usoltsev    Initial Version.
------------------------------------------------------------*/
    public static void schedule() {
        System.schedule('RetryCountClearJob', '0 0 1 * * ?', new ClearRetryCountContacts());
    }

    
    @testVisible
    private static void clearContactRetryFields() {
        List<Contact> contacts = [SELECT Id, Retry_Number_Customers__c, Retry_Number_Options__c FROM Contact WHERE Retry_Number_Customers__c > 0 OR Retry_Number_Options__c > 0];

        for (Contact cont : contacts) {
            cont.Retry_Number_Customers__c = 0;
            cont.Retry_Number_Options__c = 0;
        }

        update contacts;
    }

}