/*------------------------------------------------------------
Author:      Pavel Usoltsev
Company:     Salesforce
Description: A class to receive the customer data for existing contact by the customerId
Inputs:      contactId - id of contact to get customer number

History
8/05/18     Pavel Usoltsev    Initial version
------------------------------------------------------------*/

@isTest
private class CustomerDataController_Test {

    @isTest
    private static void testGetCustomerData() {
        String body = '{\r\n    \"Input\": {\r\n        \"InputType\": \"Phone Number\",\r\n        \"InputNumber\": \"01733404495\"\r\n    },\r\n    \"Customer\": [\r\n        {\r\n            \"CompleteCustomerFlag\": \"1\",\r\n            \"CustomerNumber\": \"2640022175\",\r\n            \"CRMType\": \"SBL\",\r\n            \"CustomerStatus\": \"AKTIV\",\r\n            \"Contract\": [\r\n                {\r\n                    \"ContractNumber\": \"40033321\",\r\n                    \"Asset\": [\r\n                        {\r\n                            \"asset_num\": \"29092834577543\",\r\n                            \"asset_type\": \"ENTITLEMENT ID\"\r\n                        }\r\n                    ],\r\n                    \"CompleteContractFlag\": \"1\"\r\n                },\r\n                {\r\n                    \"ContractNumber\": \"40034002\",\r\n                    \"Asset\": [\r\n                        {\r\n                            \"asset_num\": \"46459338272048\",\r\n                            \"asset_type\": \"ENTITLEMENT ID\"\r\n                        }\r\n                    ],\r\n                    \"CompleteContractFlag\": \"1\"\r\n                }\r\n            ]\r\n        },\r\n        {\r\n            \"CompleteCustomerFlag\": \"1\",\r\n            \"CustomerNumber\": \"1140028293\",\r\n            \"CRMType\": \"SBL\",\r\n            \"CustomerStatus\": \"AKTIV\",\r\n            \"Contract\": [\r\n                {\r\n                    \"ContractNumber\": \"40047137\",\r\n                    \"Asset\": [\r\n                        {\r\n                            \"asset_num\": \"84575282948632\",\r\n                            \"asset_type\": \"ENTITLEMENT ID\"\r\n                        }\r\n                    ],\r\n                    \"CompleteContractFlag\": \"1\"\r\n                }\r\n            ]\r\n        }\r\n    ]\r\n}';

        Test.setMock(HttpCalloutMock.class, new MockHttpResponseGenerator(body));
        System.AssertEquals(CustomerDataController.getCustomerData('1234567890').length() > 0, true);

    }
}