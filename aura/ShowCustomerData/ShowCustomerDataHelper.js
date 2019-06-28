/*------------------------------------------------------------
Author:      Pavel Usoltsev
Company:     Salesforce
History
8/01/18     Pavel Usoltsev      Initial version
31.01.2019  Sven Kretschmann    Making the callback more robust against invalid data
------------------------------------------------------------*/
({
    /*------------------------------------------------------------
    Author:      Pavel Usoltsev
    Company:     Salesforce
    Description: Get customer data from the controller
    History
    8/01/18  Pavel Usoltsev Init version
    ------------------------------------------------------------*/
    getCustomerData: function (cmp, event) {
        var customerNumber = cmp.get('v.CustomerNumber');

        if (!customerNumber) {
            cmp.set('v.isLoading', false);
            cmp.set('v.apiErrorMessage', $A.get('$Label.c.Customer_Data_Error_NoCustomerNumber'));
            return;
        }

        var action = cmp.get('c.getCustomerData');

        action.setParams({customerNumber: customerNumber});

        action.setCallback(this, function (response) {
            cmp.set('v.isLoading', false);

            var errorPrefix = $A.get('$Label.c.Customer_Data_Error_ApiFailure') + ': ';

            var state = response.getState();
            if (state === 'SUCCESS') {
                var data = JSON.parse(response.getReturnValue());

                console.log('From Server', data);

                if (data && data.CustomerData) {
                    if (typeof data.CustomerData.ContractList.Contract.length === 'undefined') {
                        /* only one contract, turn it into an array */
                        data.CustomerData.ContractList.Contract = [data.CustomerData.ContractList.Contract];
                    }

                    if (data.CustomerData.CampaignList && typeof data.CustomerData.CampaignList.CampaignElement.length === 'undefined') {
                        /* only one campaign, turn it into an array */
                        data.CustomerData.CampaignList.CampaignElement = [data.CustomerData.CampaignList.CampaignElement];
                    }

                    cmp.set('v.customerData', data.CustomerData);
                } else if (data.ErrorDesc) {
                    cmp.set('v.apiErrorMessage', errorPrefix + data.ErrorDesc);
                } else {
                    cmp.set('v.apiErrorMessage', $A.get('$Label.c.Customer_Data_Error_CustomerNotFound'));
                }
            } else if (state === 'ERROR') {
                var errors = response.getError();

                if (errors && errors[0] && errors[0].message) {
                    cmp.set('v.apiErrorMessage', errorPrefix + errors[0].message);

                    console.error('Error message: ' + errors[0].message);
                } else {
                    console.error('Unknown error', errors);
                }
            }
        });

        $A.enqueueAction(action);
    }
})