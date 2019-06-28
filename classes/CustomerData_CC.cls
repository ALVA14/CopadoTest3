/*------------------------------------------------------------
Author:      Sudipta Karmakar
Company:     Salesforce
Description: A class to receive the customer data for existing contact by the customerId
Inputs:      contactId - id of contact to get customer number
Test Class:  CustomerDataController_Test

History
8/05/18     Sudipta Karmakar    Initial version
------------------------------------------------------------*/
public with sharing class CustomerData_CC {
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
        if (String.isBlank(customerNumber)) {
            return null;
        }

        final LiveMessageSettings__c settings = LiveMessageSettings__c.getInstance();

        HttpResponse response = RequestDataReceiver.receiveHttp(settings.CustomerDataURL__c + customerNumber + CHANEL_PARAMETER, RequestDataReceiver.REQUEST_METHOD.GET.name(), settings.CustomerServiceUser__c, settings.CustomerServicePassword__c);

        if (response == null) {
            return null;
        }

        if (response.getStatusCode() != RequestDataReceiver.OK_STATUS) {
            String contentType = response.getHeader('Content-Type');
            String body = response.getBody();

            if (!String.isBlank(contentType) && contentType.startsWith('text/html')) {
                body = body.stripHtmlTags();
            }

            throw new AuraHandledException(body);
        }

        return response.getBody();
    }

}