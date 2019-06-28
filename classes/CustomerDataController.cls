/*------------------------------------------------------------
Author:      Sudipta Karmakar
Company:     Salesforce
Description: A class to receive the customer data for existing contact by the customerId
Inputs:      contactId - id of contact to get customer number
Test Class:  CustomerDataController_Test

History
8/05/18     Sudipta Karmakar    Initial version
------------------------------------------------------------*/
public with sharing class CustomerDataController {
    private static final String CHANEL_PARAMETER = '&ContactChannel=SF';

    /*------------------------------------------------------------
    Author:      Sudipta Karmakar
    Company:     Salesforce
    Description: Get customer data
    Inputs:      contactId - String id of contact to get customer number
    Returns:     response - body of the response with customer data json
    Created:     8/05/18
    ------------------------------------------------------------*/
    @AuraEnabled
    public static String getCustomerData(String customerNumber) {

        LiveMessageSettings__c settings = LiveMessageSettings__c.getInstance();

        if (customerNumber != null && String.isNotEmpty(customerNumber)) {
            String response = RequestDataReceiver.receive(settings.CustomerDataURL__c + customerNumber + CHANEL_PARAMETER, RequestDataReceiver.REQUEST_METHOD.GET.name(), settings.CustomerServiceUser__c, settings.CustomerServicePassword__c);
            return response;
        } else {
            return null;
        }
    }

}