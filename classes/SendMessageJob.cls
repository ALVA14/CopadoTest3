/*------------------------------------------------------------
Author:      Sudipta Karmakar
Company:     Salesforce
Description: A queueable class for the SmsText trigger to handle responses from customer service synchronously.
             Allow callouts for receiving data about customers from Customer service.
Inputs:      triggeredSMSTexts object values before trigger event
Test Class:  SMSTextHandler_Test

History
07/12/18    Sudipta Karmakar   Initial Version
18/01/18    Pavel Kalinin      Fixed bug from MOS-221/MOS-229
21/01/18    Pavel Kalinin      Implemented MOS-220/MOS-227
06.02.2019  Sven Kretschmann   MOS-344, allow inactive customers to pass identification
13.03.2019  Stefano Pramparo   support new parameter CustomerRowId
------------------------------------------------------------*/
public class SendMessageJob implements Queueable, Database.AllowsCallouts {

    // Avoid running nested queuable in test
    @TestVisible
    private static Boolean doChainJob = true;

    // Url parameters to receiving the customer data
    private static final String FACEBOOK_PARAMETER = 'Identifier=';
    private static final String PHONE_PARAMETER = 'PhoneNumber=';
    private static final String CHANEL_PARAMETER = '&ContactChannel=SF';

    //private static final String OPTION_MARKER = '#';

    private static final String RETRY = ' Retry';

    // Message types for a customer
    private static final String LIVE_MESSAGE_RECORD_TYPE_NAME = 'LiveMessage';
    private static final String OPTIONS_MESSAGE_TYPE = 'Options Message';
    private static final String OPTIONS_MESSAGE_RETRY_TYPE = 'Options Message Retry';
    private static final String CUSTOMER_MESSAGE_TYPE = 'Customer Message';
    private static final String CUSTOMER_MESSAGE_RETRY_TYPE = 'Customer Message Retry';

    // Limit message when exceeded number of incorrect answers

    private static final String FACEBOOK_CHANEL = 'Facebook Messenger';
    private static final String MESSAGE_STATUS_NOT_SENT = 'NotSent';

    private static final String CASE_STATUS_OPEN = 'Open';

    private static final String CUSTOM_OPTIONS_TYPE = 'MessageCustomOptionMessage';
    private static final String DEFAULT_OPTIONS_TYPE = 'DefaultOptionMessage';
    private static final String CUSTOM_CUSTOMER_TYPE = 'MessageCustomCustomerMessage';
    private static final String DEFAULT_CUSTOMER_TYPE = 'DefaultCustomerMessage';
    private static final String LIMIT_FACEBOOK_TYPE = 'Limit Message Facebook';
    private static final String LIMIT_SMS_TYPE = 'Limit Message SMS';
    private static final String GREETING_TYPE = 'GreetingMessage';

    private static LiveMessageSettings__c settings;

    private static Map<String, MessageLive__c> sentOptionMessages = new Map<String, MessageLive__c>();

    private List<LiveText__SMS_Text__c> triggeredSMSTexts;
    private List<LiveText__SMS_Text__c> messagesFromCustomers;
    private List<Id> liveMessageSessionIds;
    private List<String> originatingNumbers;

    public SendMessageJob(List<LiveText__SMS_Text__c> triggeredSMSTexts) {
        this.triggeredSMSTexts = triggeredSMSTexts;
    }

    public void execute(QueueableContext context) {
        this.messagesFromCustomers = new List<LiveText__SMS_Text__c>();
        this.liveMessageSessionIds = new List<Id>();
        this.originatingNumbers = new List<String>();

        for (LiveText__SMS_Text__c oSmsText : this.triggeredSMSTexts) {
            if (String.isNotBlank(oSmsText.LiveText__Conversation_Header__c)) {
                this.messagesFromCustomers.add(oSmsText);
                this.liveMessageSessionIds.add(oSmsText.LiveText__Conversation_Header__c);
                this.originatingNumbers.add(oSmsText.LiveText__Originating_Number__c);
            }
        }

        if (!this.messagesFromCustomers.isEmpty()) {
            processMessageFromCustomer(this.messagesFromCustomers, this.liveMessageSessionIds, this.originatingNumbers);
        }
    }

    /*------------------------------------------------------------
    Author:      Pavel Kalinin
    Company:     Salesforce
    Description: Returns the grouped by type list of responses for customer
    Inputs:      -
    Returns:     Map<String, String> list of responses grouped by message's type
    Created:     21/01/19
    ------------------------------------------------------------*/
    public static Map<String, String> getResponseMessages() {
        Map<String, String> responseMessagesByType = new Map<String, String>();

        Map<Id, RecordTypeInfo> recTypes = MessageLive__c.SObjectType.getDescribe().getRecordTypeInfosById();
        // Get active messages to auto replay for customers and prepare maps
        for (MessageLive__c oMsg : [
            SELECT
                Message__c,
                LiveMessageNumber__c,
                Starting_Line__c,
                Ending_Line__c,
                Message_Retry__c,
                RecordTypeId, (
                SELECT
                    Id,
                    Name,
                    Option_No__c,
                    OptionText__c,
                    MessageLive__c
                FROM Options__r
                ORDER BY Option_No__c ASC
            )
            FROM MessageLive__c
            WHERE Active__c = TRUE OR (
                LiveMessageNumber__c = NULL
                AND
                Active__c = FALSE
            )
        ]) {

            if (oMsg.Options__r.isEmpty()) { //response messages without options
                if (String.isBlank(oMsg.LiveMessageNumber__c)) {
                    responseMessagesByType.put(recTypes.get(oMsg.RecordTypeId).getName(), oMsg.Message__c);
                    responseMessagesByType.put(recTypes.get(oMsg.RecordTypeId).getName() + RETRY, oMsg.Message_Retry__c + '\r\n' + oMsg.Message__c);
                } else {
                    responseMessagesByType.put(oMsg.LiveMessageNumber__c + '-' + recTypes.get(oMsg.RecordTypeId).getName(), oMsg.Message__c);
                    responseMessagesByType.put(oMsg.LiveMessageNumber__c + '-' + recTypes.get(oMsg.RecordTypeId).getName() + RETRY, oMsg.Message_Retry__c + '\r\n' + oMsg.Message__c);
                }
            } else { //response messages wit options
                String optionsMessage = prepareOptions(oMsg.Options__r, oMsg, false);
                String optionsMessageRetry = prepareOptions(oMsg.Options__r, oMsg, true);

                if (String.isBlank(oMsg.LiveMessageNumber__c)) {
                    responseMessagesByType.put(recTypes.get(oMsg.RecordTypeId).getName(), optionsMessage);
                    responseMessagesByType.put(recTypes.get(oMsg.RecordTypeId).getName() + RETRY, optionsMessageRetry);
                } else {
                    responseMessagesByType.put(oMsg.LiveMessageNumber__c + '-' + recTypes.get(oMsg.RecordTypeId).getName(), optionsMessage);
                    responseMessagesByType.put(oMsg.LiveMessageNumber__c + '-' + recTypes.get(oMsg.RecordTypeId).getName() + RETRY, optionsMessageRetry);
                }
            }

            System.debug('Added custom message: ' + oMsg.Message__c);
            System.debug('oMsg.LiveMessageNumber__c: ' + oMsg.LiveMessageNumber__c);
        }

        return responseMessagesByType;
    }

    /*------------------------------------------------------------
    Author:      Pavel Usoltsev
    Company:     Salesforce
    Description: Prepare options map by the related message
    Inputs:      options - list exist options
                 messageOptions - map of exist options
    Returns:     void
    Created:     7/12/18
    ------------------------------------------------------------*/
    private static String prepareOptions(List<Option__c> options, MessageLive__c messageLive, Boolean isRetry) {
        System.debug('OPTIONS: ' + options);

        String fullMessage = '';

        if (isRetry) {
            fullMessage += messageLive.Message_Retry__c + '\n\n';
        }

        if (!String.isBlank(messageLive.Starting_Line__c)) {
            fullMessage += messageLive.Starting_Line__c + '\n\n';
        }

        for (Option__c option : options) {
            String optionText = String.isBlank(option.OptionText__c) ? option.Name : option.OptionText__c;
            fullMessage += option.Option_No__c + ') ' + optionText + '\n\n';
        }

        if (!String.isBlank(messageLive.Ending_Line__c)) {
            fullMessage += messageLive.Ending_Line__c;
        }

        if (messageLive.LiveMessageNumber__c == null) {
            sentOptionMessages.put(DEFAULT_OPTIONS_TYPE, messageLive);
        } else {
            sentOptionMessages.put(messageLive.LiveMessageNumber__c, messageLive);
        }

        return fullMessage.trim();
    }

    /*------------------------------------------------------------
    Author:      Pavel Kalinin
    Company:     Salesforce
    Description: Returns the list of existing person accounts grouped by phone numbers or facebook ids
    Inputs:      List<String> originatingNumbers - list of phone numbers or facebook ids
    Returns:     Map<String, Account> list of existing person accounts grouped by phone numbers or facebook ids
    Created:     21/01/19
    ------------------------------------------------------------*/
    public static Map<String, Account> getExistingAccounts(List<String> originatingNumbers) {
        Map<String, Account> existingAccountsByPhoneOrFbIds = new Map<String, Account>();

        // Prepare the existingAccountsByPhoneOrFbIds map by facebookId or phone
        for (Account oAccount : [
            SELECT Id, Phone, PersonContactId, CustomerId__pc, FacebookId__pc, Retry_Number_Customers__pc, Retention__pc,
                Retry_Number_Customers_Time__pc, Retry_Number_Options__pc, Retry_Number_Options_Time__pc
            FROM Account
            WHERE Phone IN :originatingNumbers OR FacebookId__pc IN :originatingNumbers
        ]) {

            if (String.isNotBlank(oAccount.Phone)) {
                existingAccountsByPhoneOrFbIds.put(oAccount.Phone, oAccount);
            } else if (String.isNotBlank(oAccount.FacebookId__pc)) {
                existingAccountsByPhoneOrFbIds.put(oAccount.FacebookId__pc, oAccount);
            }
        }

        return existingAccountsByPhoneOrFbIds;
    }

    /*------------------------------------------------------------
    Author:      Pavel Kalinin
    Company:     Salesforce
    Description: Returns the list of existing live message sessions grouped by their ids
    Inputs:      List<Id> liveMessageSessionIds - ids of live message sessions
    Returns:     Map<Id, LiveText__Conversation_Header__c> list of existing live message sessions grouped by their ids
    Created:     21/01/19
    ------------------------------------------------------------*/
    public static Map<Id, LiveText__Conversation_Header__c> getLiveMessageSessions(List<Id> liveMessageSessionIds) {
        return new Map<Id, LiveText__Conversation_Header__c>([
            SELECT Id, LiveText__Status__c, LiveText__Support_Number__c, LiveText__Formatted_Originating_Number__c,LiveText__Account__c,
                LiveText__Contact__c, LiveText__Case__c, LiveText__Case__r.Status, LiveText__LiveText_Number__c
            FROM LiveText__Conversation_Header__c
            WHERE Id IN :liveMessageSessionIds
        ]);
    }

    /*------------------------------------------------------------
    Author:      Pavel Kalinin
    Company:     Salesforce
    Description: Returns the list of existing cases grouped by phone numbers or facebook ids
    Inputs:      List<Account> existingAccounts - list of existing person accounts
    Returns:     Map<String, Case> list of existing cases grouped by phone numbers or facebook ids
    Created:     21/01/19
    ------------------------------------------------------------*/
    public static Map<String, Case> getExistingCases(List<Account> existingAccounts) {
        Map<String, Case> existingCasesByPhoneOrFbIds = new Map<String, Case>();

        // Prepare the existingCasesByPhoneOrFbIds map by facebookId or phone
        for (Case oCase : [
            SELECT Id, Contact.Phone, Contact.FacebookId__c
            FROM Case
            WHERE AccountId IN :existingAccounts AND IsClosed != true
        ]) {

            if (String.isNotBlank(oCase.Contact.Phone)) {
                existingCasesByPhoneOrFbIds.put(oCase.Contact.Phone, oCase);
            } else if (String.isNotBlank(oCase.Contact.FacebookId__c)) {
                existingCasesByPhoneOrFbIds.put(oCase.Contact.FacebookId__c, oCase);
            }
        }

        return existingCasesByPhoneOrFbIds;
    }

    /*------------------------------------------------------------
    Author:      Sudipta Karmakar
    Company:     Salesforce
    Description: Prepare collections for 4 cases for received the customer message

                 1) Create contacts and accounts for messages received from unknown customers and  ask customer about customer number if it doesn't exist for SF contact or ask options if it present
                 2) If the customer number doesn't exist check it on external Customer service.
                 If customer not founded in external Customer service or provided customer number hs incorrect format - ask again about customer number,
                 another way - ask customer about options
                 3) Create case for customer, if chosen option is incorrect ask customer again about correct option
                 4) Ask customer about customer number if it doesn't exist for SF contact or ask options if it present

    Inputs:      SMS text received from the trigger
                 -
                 -
    Returns:     true
    Created:     7/12/18
    ------------------------------------------------------------*/
    public static Boolean processMessageFromCustomer(List<LiveText__SMS_Text__c> messagesFromCustomers, List<Id> liveMessageSessionIds, List<String> originatingNumbers) {
        settings = LiveMessageSettings__c.getInstance();

        Map<String, String> responseMessagesByType = getResponseMessages();
        System.debug('responseMessagesByType: ' + responseMessagesByType);

        Map<String, Account> existingAccountsByPhoneOrFbIds = getExistingAccounts(originatingNumbers);
        System.debug('List of all person accounts: ' + existingAccountsByPhoneOrFbIds);

        Map<Id, LiveText__Conversation_Header__c> liveMessageSessions = getLiveMessageSessions(liveMessageSessionIds);
        System.debug('Map of session headers: ' + liveMessageSessions);

        Map<String, Case> existingCasesByPhoneOrFbIds = getExistingCases(existingAccountsByPhoneOrFbIds.values());
        System.debug('List of all cases: ' + existingCasesByPhoneOrFbIds);

        List<LiveText__SMS_Text__c> firstMessagesFromNewCustomers = new List<LiveText__SMS_Text__c>();
        List<LiveText__SMS_Text__c> firstMessagesFromExistingCustomers = new List<LiveText__SMS_Text__c>();
        List<LiveText__SMS_Text__c> messagesForCustomerNumbers = new List<LiveText__SMS_Text__c>();
        List<LiveText__SMS_Text__c> messagesForCaseOptions = new List<LiveText__SMS_Text__c>();

        LiveText__Conversation_Header__c currentSession;
        // For each received message from the customer need to prepare collections:
        for (LiveText__SMS_Text__c oSmsText : messagesFromCustomers) {

            System.debug('Received message from customer: ' + oSmsText);

            if (liveMessageSessions.isEmpty()
                ||
                oSmsText.LiveText__Conversation_Header__c == null
                ||
                liveMessageSessions.get(oSmsText.LiveText__Conversation_Header__c).LiveText__Status__c != 'New'
                ) {
                continue;
            }

            currentSession = liveMessageSessions.get(oSmsText.LiveText__Conversation_Header__c);
            System.debug('Current session: ' + currentSession);

            if (currentSession.LiveText__Account__c == null && currentSession.LiveText__Case__c == null
                && !existingAccountsByPhoneOrFbIds.containsKey(oSmsText.LiveText__Originating_Number__c)) {

                firstMessagesFromNewCustomers.add(oSmsText);

            } else if (currentSession.LiveText__Account__c == null && currentSession.LiveText__Case__c == null
                && existingAccountsByPhoneOrFbIds.containsKey(oSmsText.LiveText__Originating_Number__c)) {

                firstMessagesFromExistingCustomers.add(oSmsText);

            } else if (currentSession.LiveText__Account__c != null
                && existingAccountsByPhoneOrFbIds.containsKey(oSmsText.LiveText__Originating_Number__c)
                && String.isBlank(existingAccountsByPhoneOrFbIds.get(oSmsText.LiveText__Originating_Number__c).CustomerId__pc)) {

                messagesForCustomerNumbers.add(oSmsText);

            } else if (currentSession.LiveText__Account__c != null && currentSession.LiveText__Case__c == null
                && existingAccountsByPhoneOrFbIds.containsKey(oSmsText.LiveText__Originating_Number__c)
                && String.isNotBlank(existingAccountsByPhoneOrFbIds.get(oSmsText.LiveText__Originating_Number__c).CustomerId__pc)) {

                messagesForCaseOptions.add(oSmsText);

            }
        }

        Map<String, LiveText__SMS_Message__c> mapSendNextMessage = new Map<String, LiveText__SMS_Message__c>();

        // Create contacts and accounts for messages received from unknown customers and  ask customer about customer number if it doesn't exist for SF contact or ask options if it present
        if (!firstMessagesFromNewCustomers.isEmpty()) {
            mapSendNextMessage.putAll(createPersonAccountForNewCustomer(firstMessagesFromNewCustomers, liveMessageSessions, responseMessagesByType));
        }

        // Ask customer about customer number if it doesn't exist for SF contact or ask options if it present
        if (!firstMessagesFromExistingCustomers.isEmpty()) {
            mapSendNextMessage.putAll(checkExistingCustomer(firstMessagesFromExistingCustomers, liveMessageSessions, existingAccountsByPhoneOrFbIds, existingCasesByPhoneOrFbIds, responseMessagesByType));
        }

        // If the customer number doesn't exist check it on external Customer service.
        // If customer not founded in external Customer service or provided customer number hs incorrect format - ask again about customer number,
        // another way - ask customer about options
        if (!messagesForCustomerNumbers.isEmpty()) {
            mapSendNextMessage.putAll(checkCustomerNumber(messagesForCustomerNumbers, liveMessageSessions, existingAccountsByPhoneOrFbIds, responseMessagesByType));
        }

        // Create case for customer, if chosen option is incorrect ask customer again about correct option
        if (!messagesForCaseOptions.isEmpty()) {
            mapSendNextMessage.putAll(checkSelectedOption(messagesForCaseOptions, liveMessageSessions, existingAccountsByPhoneOrFbIds, responseMessagesByType));
        }

        System.debug('Sms map for case options: ' + messagesForCaseOptions);
        System.debug('Sms map for customers without customer number: ' + messagesForCustomerNumbers);
        System.debug('Messages to send: ' + mapSendNextMessage);

        if (!mapSendNextMessage.isEmpty() && doChainJob) {
            System.enqueueJob(new QueueMessageClass(mapSendNextMessage.values()));
        }

        return true;
    }

    private static Map<String, LiveText__SMS_Message__c> checkExistingCustomer(
        List<LiveText__SMS_Text__c> firstMessagesFromExistingCustomers,
        Map<Id, LiveText__Conversation_Header__c> liveMessageSessions,
        Map<String, Account> existingAccountsByPhoneOrFbIds,
        Map<String, Case> existingCasesByPhoneOrFbIds,
        Map<String, String> responseMessagesByType
    ) {

        Map<String, LiveText__SMS_Message__c> mapSendNextMessage = new Map<String, LiveText__SMS_Message__c>();

        List<Case> cesesToReopen = new List<Case>();

        for (LiveText__SMS_Text__c oSmsText : firstMessagesFromExistingCustomers) {

            liveMessageSessions.get(oSmsText.LiveText__Conversation_Header__c).LiveText__Account__c = existingAccountsByPhoneOrFbIds.get(oSmsText.LiveText__Originating_Number__c).Id;
            liveMessageSessions.get(oSmsText.LiveText__Conversation_Header__c).LiveText__Contact__c = existingAccountsByPhoneOrFbIds.get(oSmsText.LiveText__Originating_Number__c).PersonContactId;

            if (String.isBlank(existingAccountsByPhoneOrFbIds.get(oSmsText.LiveText__Originating_Number__c).CustomerId__pc)) {

                mapSendNextMessage.putAll(prepareMessageToSend(oSmsText, responseMessagesByType, CUSTOMER_MESSAGE_TYPE, MESSAGE_STATUS_NOT_SENT));

            } else if (String.isNotBlank(existingAccountsByPhoneOrFbIds.get(oSmsText.LiveText__Originating_Number__c).CustomerId__pc) && !existingCasesByPhoneOrFbIds.containsKey(oSmsText.LiveText__Originating_Number__c)) {
                mapSendNextMessage.putAll(prepareMessageToSend(oSmsText, responseMessagesByType, GREETING_TYPE, MESSAGE_STATUS_NOT_SENT));

                // Ask options
                mapSendNextMessage.putAll(prepareMessageToSend(oSmsText, responseMessagesByType, OPTIONS_MESSAGE_TYPE, MESSAGE_STATUS_NOT_SENT));

            } else if (String.isNotBlank(existingAccountsByPhoneOrFbIds.get(oSmsText.LiveText__Originating_Number__c).CustomerId__pc) && existingCasesByPhoneOrFbIds.containsKey(oSmsText.LiveText__Originating_Number__c)) {
                liveMessageSessions.get(oSmsText.LiveText__Conversation_Header__c).LiveText__Case__c = existingCasesByPhoneOrFbIds.get(oSmsText.LiveText__Originating_Number__c).Id;
                Case oCase = new Case();
                oCase.put('Id', existingCasesByPhoneOrFbIds.get(oSmsText.LiveText__Originating_Number__c).Id);
                oCase.put('Status', CASE_STATUS_OPEN);
                cesesToReopen.add(oCase);
            }
        }

        if (!liveMessageSessions.isEmpty()) {
            update liveMessageSessions.values();
        }

        if (!cesesToReopen.isEmpty()) {
            update cesesToReopen;
        }

        return mapSendNextMessage;
    }

    private static Map<String, LiveText__SMS_Message__c> checkCustomerNumber(
        List<LiveText__SMS_Text__c> messagesForCustomerNumbers,
        Map<Id, LiveText__Conversation_Header__c> liveMessageSessions,
        Map<String, Account> existingAccountsByPhoneOrFbIds,
        Map<String, String> responseMessagesByType
    ) {

        Map<String, LiveText__SMS_Message__c> mapSendNextMessage = new Map<String, LiveText__SMS_Message__c>();

        Account currentPersonAccount;
        for (LiveText__SMS_Text__c oSmsText : messagesForCustomerNumbers) {
            currentPersonAccount = existingAccountsByPhoneOrFbIds.get(oSmsText.LiveText__Originating_Number__c);

            Decimal numberOfRetries;
            Decimal minutesToBlock;
            String limitMessage;
            if (liveMessageSessions.get(oSmsText.LiveText__Conversation_Header__c).LiveText__LiveText_Number__c == FACEBOOK_CHANEL) {
                numberOfRetries = settings.NumberOfFacebookRetries__c;
                minutesToBlock = settings.MinutesToBlockAfterFbRetriesLimit__c;
                limitMessage = LIMIT_FACEBOOK_TYPE;
            } else {
                numberOfRetries = settings.NumberOfRetries__c;
                minutesToBlock = settings.MinutesToBlockAfterRetriesLimit__c;
                limitMessage = LIMIT_SMS_TYPE;
            }

            if (currentPersonAccount.Retry_Number_Customers_Time__pc != null
                && currentPersonAccount.Retry_Number_Customers_Time__pc.addMinutes(Integer.valueOf(minutesToBlock)) > Datetime.now()) {
                // user has already reached retry limit -> set block time to now -> show block message
                mapSendNextMessage.putAll(prepareMessageToSend(oSmsText, responseMessagesByType, limitMessage, MESSAGE_STATUS_NOT_SENT));
                return mapSendNextMessage;
            }

            Boolean isRightFormat = true;
            String customerNumber = oSmsText.LiveText__Message__c;

            if (String.isNotBlank(settings.CustomerNumberRegEx__c)) {
                isRightFormat = Pattern.compile(settings.CustomerNumberRegEx__c).matcher(customerNumber).matches();
            }

            System.debug('Configured length: ' + settings.CustomerNumberRegEx__c + ' Customer number: ' + customerNumber);

            Account personAccount;

            if (isRightFormat) {
                personAccount = getCustomerServiceData(null, customerNumber);
            }

            if (personAccount != null) {
                currentPersonAccount.Retry_Number_Customers_Time__pc = null;
                currentPersonAccount.Retry_Number_Customers__pc = 0;

                currentPersonAccount.FAA_Failed__c = personAccount.FAA_Failed__c;

                currentPersonAccount.CustomerId__pc = customerNumber;
                currentPersonAccount.SmartCardId__pc = personAccount.SmartCardId__pc;
                currentPersonAccount.Contract_Number__pc = personAccount.Contract_Number__pc;
				currentPersonAccount.CustomerRowId__pc = personAccount.CustomerRowId__pc;
                mapSendNextMessage.putAll(prepareMessageToSend(oSmsText, responseMessagesByType, OPTIONS_MESSAGE_TYPE, MESSAGE_STATUS_NOT_SENT));
            } else {
                currentPersonAccount.Retry_Number_Customers__pc += 1;

                if ((numberOfRetries == null) || (numberOfRetries <= 0) || (minutesToBlock == null) || (minutesToBlock <= 0)) {
                    // block functionality is not applicable -> show retry message
                    currentPersonAccount.Retry_Number_Customers_Time__pc = null;
                } else if (currentPersonAccount.Retry_Number_Customers_Time__pc != null
                    && currentPersonAccount.Retry_Number_Customers_Time__pc.addMinutes(Integer.valueOf(minutesToBlock)) <= Datetime.now()) {
                    // block time is lesft -> clear block time -> show retry message
                    currentPersonAccount.Retry_Number_Customers_Time__pc = null;
                    currentPersonAccount.Retry_Number_Customers__pc = 1;
                } else if (currentPersonAccount.Retry_Number_Customers_Time__pc == null && numberOfRetries <= currentPersonAccount.Retry_Number_Customers__pc) {
                    // user has reached retry limit -> set block time to now -> show block message
                    currentPersonAccount.Retry_Number_Customers_Time__pc = Datetime.now();
                }

                if (currentPersonAccount.Retry_Number_Customers_Time__pc == null) {
                    mapSendNextMessage.putAll(prepareMessageToSend(oSmsText, responseMessagesByType, CUSTOMER_MESSAGE_RETRY_TYPE, MESSAGE_STATUS_NOT_SENT));
                } else if (currentPersonAccount.Retry_Number_Customers_Time__pc != null) {
                    mapSendNextMessage.putAll(prepareMessageToSend(oSmsText, responseMessagesByType, limitMessage, MESSAGE_STATUS_NOT_SENT));
                }
            }
        }

        if (!existingAccountsByPhoneOrFbIds.isEmpty() && messagesForCustomerNumbers != null && !messagesForCustomerNumbers.isEmpty()) {
            update existingAccountsByPhoneOrFbIds.values();
        }

        return mapSendNextMessage;

    }

    private static Map<String, LiveText__SMS_Message__c> createPersonAccountForNewCustomer(
        List<LiveText__SMS_Text__c> firstMessagesFromNewCustomers,
        Map<Id, LiveText__Conversation_Header__c> liveMessageSessions,
        Map<String, String> responseMessagesByType
    ) {

        Map<String, LiveText__SMS_Message__c> mapSendNextMessage = new Map<String, LiveText__SMS_Message__c>();

        Map<Id, Account> mapAccountsToInsert = new Map<Id, Account>();
        Set<String> listOfPhoneNumbersNotSendMessage = new Set<String>();

        Id recordTypeIdPersonAccount = Schema.SObjectType.Account.getRecordTypeInfosByName().get(LIVE_MESSAGE_RECORD_TYPE_NAME).getRecordTypeId();

        for (LiveText__SMS_Text__c oSmsText : firstMessagesFromNewCustomers) {

            mapSendNextMessage.putAll(prepareMessageToSend(oSmsText, responseMessagesByType, GREETING_TYPE, MESSAGE_STATUS_NOT_SENT));

            Account oAccount = new Account();
            oAccount.RecordTypeId = recordTypeIdPersonAccount;
            oAccount.LastName = liveMessageSessions.get(oSmsText.LiveText__Conversation_Header__c).LiveText__Formatted_Originating_Number__c;

            if (liveMessageSessions.get(oSmsText.LiveText__Conversation_Header__c).LiveText__LiveText_Number__c == FACEBOOK_CHANEL) {

                oAccount.FacebookId__pc = oSmsText.LiveText__Originating_Number__c;
                mapAccountsToInsert.put(oSmsText.Id, oAccount);

            } else {

                oAccount.Phone = oSmsText.LiveText__Originating_Number__c;
                Account receivedAccount = getCustomerServiceData('0' + oAccount.Phone.substring(3, oAccount.Phone.length()), null);

                if (receivedAccount != null) {
                    oAccount.FAA_Failed__c = receivedAccount.FAA_Failed__c;
                    oAccount.CustomerId__pc = receivedAccount.CustomerId__pc;
                    oAccount.SmartCardId__pc = receivedAccount.SmartCardId__pc;
                    oAccount.Contract_Number__pc = receivedAccount.Contract_Number__pc;
                    oAccount.CustomerRowId__pc = receivedAccount.CustomerRowId__pc;
                    listOfPhoneNumbersNotSendMessage.add(oSmsText.Id);
                }

                mapAccountsToInsert.put(oSmsText.Id, oAccount);
            }

        }

        if (!mapAccountsToInsert.isEmpty()) {
            insert mapAccountsToInsert.values();
        }

        Map<Id, LiveText__Conversation_Header__c> mapLiveMsgHeaderToUpdate = new Map<Id, LiveText__Conversation_Header__c>();

        for (LiveText__SMS_Text__c oSmsText : firstMessagesFromNewCustomers) {

            LiveText__Conversation_Header__c oHeader = new LiveText__Conversation_Header__c();
            oHeader.Id = oSmsText.LiveText__Conversation_Header__c;
            oHeader.LiveText__Contact__c = mapAccountsToInsert.get(oSmsText.Id).PersonContactId;
            oHeader.LiveText__Account__c = mapAccountsToInsert.get(oSmsText.Id).Id;
            mapLiveMsgHeaderToUpdate.put(oHeader.Id, oHeader);

            System.debug('Map contacts to insert: ' + mapAccountsToInsert);
            System.debug('Current sms text: ' + oSmsText);
            System.debug('Contact id to insert: ' + mapAccountsToInsert.get(oSmsText.Id).PersonContactId);

            if (!listOfPhoneNumbersNotSendMessage.contains(oSmsText.Id)) {

                mapSendNextMessage.putAll(prepareMessageToSend(oSmsText, responseMessagesByType, CUSTOMER_MESSAGE_TYPE, MESSAGE_STATUS_NOT_SENT));

            } else {

                mapSendNextMessage.putAll(prepareMessageToSend(oSmsText, responseMessagesByType, OPTIONS_MESSAGE_TYPE, MESSAGE_STATUS_NOT_SENT));

            }
        }

        if (!mapLiveMsgHeaderToUpdate.isEmpty()) {
            update mapLiveMsgHeaderToUpdate.values();
        }

        return mapSendNextMessage;
    }

    private static Map<String, LiveText__SMS_Message__c> checkSelectedOption(
        List<LiveText__SMS_Text__c> messagesForCaseOptions,
        Map<Id, LiveText__Conversation_Header__c> liveMessageSessions,
        Map<String, Account> existingAccountsByPhoneOrFbIds,
        Map<String, String> responseMessagesByType
    ) {

        Map<String, LiveText__SMS_Message__c> mapSendNextMessage = new Map<String, LiveText__SMS_Message__c>();

        Map<String, Case> mapCaseBySMS = new Map<String, Case>();

        Id recordTypeIdCase = Schema.SObjectType.Case.getRecordTypeInfosByName().get(LIVE_MESSAGE_RECORD_TYPE_NAME).getRecordTypeId();

        Account currentPersonAccount;
        for (LiveText__SMS_Text__c oSmsText : messagesForCaseOptions) {
            currentPersonAccount = existingAccountsByPhoneOrFbIds.get(oSmsText.LiveText__Originating_Number__c);

            Decimal numberOfRetries;
            Decimal minutesToBlock;
            String limitMessage;
            if (liveMessageSessions.get(oSmsText.LiveText__Conversation_Header__c).LiveText__LiveText_Number__c == FACEBOOK_CHANEL) {
                numberOfRetries = settings.NumberOfFacebookRetries__c;
                minutesToBlock = settings.MinutesToBlockAfterFbRetriesLimit__c;
                limitMessage = LIMIT_FACEBOOK_TYPE;
            } else {
                numberOfRetries = settings.NumberOfRetries__c;
                minutesToBlock = settings.MinutesToBlockAfterRetriesLimit__c;
                limitMessage = LIMIT_SMS_TYPE;
            }

            if (currentPersonAccount.Retry_Number_Options_Time__pc != null
                && currentPersonAccount.Retry_Number_Options_Time__pc.addMinutes(Integer.valueOf(minutesToBlock)) > Datetime.now()) {
                // user has already reached retry limit -> show block message
                mapSendNextMessage.putAll(prepareMessageToSend(oSmsText, responseMessagesByType, limitMessage, MESSAGE_STATUS_NOT_SENT));
                return mapSendNextMessage;
            }

            currentPersonAccount.Retry_Number_Customers_Time__pc = null;
            currentPersonAccount.Retry_Number_Customers__pc = 0;

            String optionText = getSelectedSupportOption(oSmsText, liveMessageSessions);

            if (optionText != null) {
                currentPersonAccount.Retry_Number_Options_Time__pc = null;
                currentPersonAccount.Retry_Number_Options__pc = 0;

                List<Group> queues = [SELECT Id, OwnerId FROM Group WHERE Type = 'Queue' AND Name = 'OmniQueueLv1'];

                // separate method need
                Case oCase = new Case();

                oCase.RecordTypeId = recordTypeIdCase;

                if (queues.size() > 0) {
                    oCase.OwnerId = queues.get(0).OwnerId;
                }

                oCase.ContactId = currentPersonAccount.PersonContactId;
                oCase.AccountId = currentPersonAccount.Id;
                oCase.Subject = optionText;
                oCase.Origin = liveMessageSessions.get(oSmsText.LiveText__Conversation_Header__c).LiveText__LiveText_Number__c == FACEBOOK_CHANEL ? 'Facebook' : 'SMS';
                oCase.SupportOption__c = optionText;
                oCase.Status = CASE_STATUS_OPEN;
                oCase.Is_Retention__c = isRetentionCustomer(currentPersonAccount.CustomerId__pc, settings);
                mapCaseBySMS.put(oSmsText.Id, oCase);
            } else {
                currentPersonAccount.Retry_Number_Options__pc += 1;
                if ((numberOfRetries == null) || (numberOfRetries <= 0) || (minutesToBlock == null) || (minutesToBlock <= 0)) {
                    // block functionality is not applicable -> show retry message
                    currentPersonAccount.Retry_Number_Options_Time__pc = null;
                } else if (currentPersonAccount.Retry_Number_Options_Time__pc != null
                    && currentPersonAccount.Retry_Number_Options_Time__pc.addMinutes(Integer.valueOf(minutesToBlock)) <= Datetime.now()) {
                    // block time is lesft -> clear block time -> show retry message
                    currentPersonAccount.Retry_Number_Options_Time__pc = null;
                    currentPersonAccount.Retry_Number_Options__pc = 1;
                } else if (currentPersonAccount.Retry_Number_Options_Time__pc == null && numberOfRetries <= currentPersonAccount.Retry_Number_Options__pc) {
                    // user has reached retry limit -> set block time to now -> show block message
                    currentPersonAccount.Retry_Number_Options_Time__pc = Datetime.now();
                }

                if (currentPersonAccount.Retry_Number_Options_Time__pc == null) {
                    // block functionality is not applicable or user has not reached retry limit -> show retry message
                    mapSendNextMessage.putAll(prepareMessageToSend(oSmsText, responseMessagesByType, OPTIONS_MESSAGE_RETRY_TYPE, MESSAGE_STATUS_NOT_SENT));
                } else if (currentPersonAccount.Retry_Number_Options_Time__pc != null) {
                    // block functionality is applicable and user has reached retry limit -> show block message
                    mapSendNextMessage.putAll(prepareMessageToSend(oSmsText, responseMessagesByType, limitMessage, MESSAGE_STATUS_NOT_SENT));
                }
            }
        }

        if (!existingAccountsByPhoneOrFbIds.isEmpty()) {
            update existingAccountsByPhoneOrFbIds.values();
        }

        if (!mapCaseBySMS.isEmpty()) {
            Database.insert(mapCaseBySMS.values(), false);
        }

        for (LiveText__SMS_Text__c oSmsText : messagesForCaseOptions) {
            if (mapCaseBySMS.containsKey(oSmsText.Id)) {
                liveMessageSessions.get(oSmsText.LiveText__Conversation_Header__c).LiveText__Case__c = mapCaseBySMS.get(oSmsText.Id).Id;
            }
        }

        if (!liveMessageSessions.isEmpty()) {
            update liveMessageSessions.values();
        }

        return mapSendNextMessage;
    }

    /*------------------------------------------------------------
    Description: Parse received option
    Inputs: oSmsText - received sms from the customer
    Returns: String - text of option
    Created: 7/12/18
    ------------------------------------------------------------*/
    private static String getSelectedSupportOption(LiveText__SMS_Text__c oSmsText, Map<Id, LiveText__Conversation_Header__c> sessions) {
        String input = oSmsText.LiveText__Message__c;

        if (!String.isBlank(input) && input.isNumeric()) {
            List<Option__c> options;

            System.debug('sentOptionMessages: ' + sentOptionMessages);
            String channel = sessions.get(oSmsText.LiveText__Conversation_Header__c).LiveText__Support_Number__c;

            if (sentOptionMessages.containsKey(channel)) {
                options = sentOptionMessages.get(channel).Options__r;
            } else {
                options = sentOptionMessages.get(DEFAULT_OPTIONS_TYPE).Options__r;
            }

            for (Option__c option : options) {
                if (option.Option_No__c == input) {
                    return option.Name;
                }
            }
        }

        return null;
    }

    /*------------------------------------------------------------
    Description: Prepare the message that will be sent for customer
    Inputs: oSmsText - received sms from the customer
        responseMessagesByType - messages for the customer by the chanel
        mapSendNextMessage - map with prepared messages to send
        message - message to send
        type = type of message to send
        status - message status
    Returns: void
    Created: 7/12/18
    ------------------------------------------------------------*/
    public static Map<String, LiveText__SMS_Message__c> prepareMessageToSend(LiveText__SMS_Text__c oSmsText, Map<String, String> responseMessagesByType, String type, String status) {

        LiveText__SMS_Message__c oOb = new LiveText__SMS_Message__c();
        oOb.LiveText__LiveText_Number__c = oSmsText.LiveText__Support_Number__c;

        String messageType = 'Default';
        String defaultMessageType = 'Default';

        if (OPTIONS_MESSAGE_TYPE == type) {
            messageType = CUSTOM_OPTIONS_TYPE;
            defaultMessageType = DEFAULT_OPTIONS_TYPE;
        }

        if (OPTIONS_MESSAGE_RETRY_TYPE == type) {
            messageType = CUSTOM_OPTIONS_TYPE + RETRY;
            defaultMessageType = DEFAULT_OPTIONS_TYPE + RETRY;
        }

        if (CUSTOMER_MESSAGE_TYPE == type) {
            messageType = CUSTOM_CUSTOMER_TYPE;
            defaultMessageType = DEFAULT_CUSTOMER_TYPE;
        }

        if (CUSTOMER_MESSAGE_RETRY_TYPE == type) {
            messageType = CUSTOM_CUSTOMER_TYPE + RETRY;
            defaultMessageType = DEFAULT_CUSTOMER_TYPE + RETRY;
        }

        if (LIMIT_SMS_TYPE == type) {
            messageType = LIMIT_SMS_TYPE;
            defaultMessageType = LIMIT_SMS_TYPE;
        }

        if (LIMIT_FACEBOOK_TYPE == type) {
            messageType = LIMIT_FACEBOOK_TYPE;
            defaultMessageType = LIMIT_FACEBOOK_TYPE;
        }

        if (GREETING_TYPE == type) {
            messageType = GREETING_TYPE;
            defaultMessageType = GREETING_TYPE;
        }

        System.debug('TYPE: ' + type);

        System.debug('SUPPORT NUMBER: ' + oSmsText.LiveText__Support_Number__c);

        System.debug('MESSAGE MAP: ' + responseMessagesByType);

        if (responseMessagesByType.containsKey(oSmsText.LiveText__Support_Number__c + '-' + messageType)) {
            oOb.LiveText__Message__c = responseMessagesByType.get(oSmsText.LiveText__Support_Number__c + '-' + messageType);
        } else {
            oOb.LiveText__Message__c = responseMessagesByType.get(defaultMessageType);
        }

        oOb.LiveText__Object_Id__c = oSmsText.LiveText__Conversation_Header__c;
        oOb.LiveText__Message_Status__c = status;
        oOb.LiveText__To_Phone_Number__c = oSmsText.LiveText__Originating_Number__c;

        System.debug('SENT MESSAGE: ' + oOb);

        return new Map<String, LiveText__SMS_Message__c>{
            oSmsText.Id + '-' + messageType => oOb
        };

    }

    /*------------------------------------------------------------
    Author:      Pavel Usoltsev
    Company:     Salesforce
    Description: Check the data for customer in Customer service by phone number or customer number
    Inputs:      phoneNumber - if not null check by phone
             customerNumber - if not null check by the customer number
    Returns:     PersonAccount - founded contact in customer service
             null - if contact is not found
    ------------------------------------------------------------*/
    private static Account getCustomerServiceData(String phoneNumber, String customerNumber) {
        System.debug('Phone number: ' + phoneNumber);

        HttpResponse response;
        if (String.isNotBlank(phoneNumber)) {
            response = RequestDataReceiver.receiveHttp(
                settings.CustomerServiceURL__c + PHONE_PARAMETER + phoneNumber + CHANEL_PARAMETER,
                RequestDataReceiver.REQUEST_METHOD.GET.name(),
                settings.CustomerServiceUser__c,
                settings.CustomerServicePassword__c
            );
        } else {
            response = RequestDataReceiver.receiveHttp(
                settings.CustomerServiceURL__c + FACEBOOK_PARAMETER + customerNumber + CHANEL_PARAMETER,
                RequestDataReceiver.REQUEST_METHOD.GET.name(),
                settings.CustomerServiceUser__c,
                settings.CustomerServicePassword__c
            );
        }
        System.debug('Response: ' + response);

        //exception is occured or customer is not found
        if (response == null || response.getStatusCode() == RequestDataReceiver.NOT_FOUND_STATUS) {
            return null;
        }

        Account accountData = new Account();

        //mark account as faa failed if callout was not successful
        if (response.getStatusCode() != RequestDataReceiver.OK_STATUS) {
            accountData.FAA_Failed__c = true;
            return accountData;
        }

        String responseBody = response.getBody();

        try {
            CustomerServiceResponseWrapper data = (CustomerServiceResponseWrapper) JSON.deserialize(responseBody, CustomerServiceResponseWrapper.class);

            if (data.Customer == null) {
                return null;
            }

            Map<String, String> foundNumbers = new Map<String, String>();

            String smartCardId;

            for (Customer customer : data.Customer) {
                // there is no contract - move to the next customer
                if (customer.isFieldExists('Contract') != true || customer.Contract == null) {
                    continue;
                }

                String contractNumberKey = customer.CustomerStatus == 'AKTIV' ? 'activeContract' : 'inactiveContract';

                if (String.isBlank(customerNumber)) {
                    customerNumber = customer.CustomerNumber;
                }
                accountData.CustomerRowId__pc=customer.CustomerRowId;
                for (Contract contract : customer.Contract) {
                    // save the number of the first contract in case there are no assets
                    if (!foundNumbers.containsKey(contractNumberKey)) {
                        foundNumbers.put(contractNumberKey, contract.ContractNumber);
                    }

                    // there are no assets in that contract - move to the next contract
                    if (contract.isFieldExists('Asset') != true || contract.Asset == null) {
                        continue;
                    }

                    for (Asset asset : contract.Asset) {
                        smartCardId = asset.asset_num;

                        if (!foundNumbers.containsKey(contractNumberKey + 'WithAsset')) {
                            foundNumbers.put(contractNumberKey + 'WithAsset', contract.ContractNumber);
                        }

                        break;
                    }

                    // asset is already found - break the loop
                    if (String.isNotBlank(smartCardId)) {
                        break;
                    }

                }

                // asset is already found - break the loop
                if (String.isNotBlank(smartCardId)) {
                    break;
                }
            }

            List<String> tryContractNumberKeys = new List<String>{
                'activeContractWithAsset',
                'activeContract',
                'inactiveContractWithAsset',
                'inactiveContract'
            };

            for (String contractNumberKey : tryContractNumberKeys) {
                if (foundNumbers.containsKey(contractNumberKey)) {
                    accountData.FAA_Failed__c = false;
                    accountData.CustomerId__pc = customerNumber;
                    accountData.Contract_Number__pc = foundNumbers.get(contractNumberKey);
                    break;
                }
            }

            if (String.isNotBlank(smartCardId)) {
                accountData.SmartCardId__pc = smartCardId;
            }

            System.debug('CustomerRowId__c ' + accountData.CustomerRowId__pc);
            System.debug('CustomerId__c ' + accountData.CustomerId__pc);
            System.debug('Contract_Number__c ' + accountData.Contract_Number__pc);
            System.debug('SmartCardId__c ' + accountData.SmartCardId__pc);

            System.debug('PARSED response: ' + data);
        } catch (Exception e) {
            System.debug('ERROR PARSING RESPONSE: ' + responseBody + ' ::: ' + e);
        }

        return accountData;

    }

    /*------------------------------------------------------------
    Author:      Pavel Kalinin
    Company:     Salesforce
    Description: Checks whether the customer is retention or not
    Inputs:      customerId - customer's id
                 settings - LiveMessageSettings__c custom setting
    Returns:     Boolean - if true - customer is renetension, otherwise returns false
    Created:     14/01/19
    ------------------------------------------------------------*/
    public static Boolean isRetentionCustomer(String customerId, LiveMessageSettings__c settings) {
        Boolean isRetention = false;
        String response = '';

        try {
            response = RequestDataReceiver.receive(
                settings.CustomerDataURL__c + customerId + CHANEL_PARAMETER,
                RequestDataReceiver.REQUEST_METHOD.GET.name(),
                settings.CustomerServiceUser__c,
                settings.CustomerServicePassword__c
            );

            Map<String, Object> responseMap = (Map<String, Object>) JSON.deserializeUntyped(response);
            Map<String, Object> customerDataMap = (Map<String, Object>) responseMap.get('CustomerData');
            Map<String, Object> campaignElementMap = (Map<String, Object>) customerDataMap.get('CampaignList');
            //we do serialize CampaignElement because it might be an object or an array
            String campaignElementJSON = JSON.serialize(campaignElementMap.get('CampaignElement'));

            List<CampaignElement> campaigns;
            if (campaignElementJSON.startsWith('[')) {
                campaigns = (List<CampaignElement>) JSON.deserialize(campaignElementJSON, List<CampaignElement>.class);
            } else {
                campaigns = new List<CampaignElement>{
                    (CampaignElement) JSON.deserialize(campaignElementJSON, CampaignElement.class)
                };
            }

            for (CampaignElement campaign : campaigns) {
                if (settings.RetentionCampaignType__c.contains(campaign.CampaignType)) {
                    isRetention = true;
                    break;
                }
            }
        } catch (Exception e) {
            System.debug('ERROR PARSING RESPONSE: ' + response + ' ::: ' + e);
        }

        return isRetention;
    }

    /*------------------------------------------------------------
    Author:      Pavel Usoltsev
    Company:     Salesforce
    Description: Wrapper classes for customer service response
    Inputs:
    Returns:
    Created:     25/07/2018
    ------------------------------------------------------------*/

    public class Input extends CoreObject {
        public String InputType {
            get;
            set;
        }
        public String InputNumber {
            get;
            set;
        }
    }

    public class Asset extends CoreObject {
        public String asset_num {
            get;
            set;
        }
        public String asset_type {
            get;
            set;
        }
    }

    public class Contract extends CoreObject {
        public String ContractNumber {
            get;
            set;
        }
        public Asset[] Asset {
            get;
            set;
        }
        public String CompleteContractFlag {
            get;
            set;
        }
    }

    public class Customer extends CoreObject {
        public String CompleteCustomerFlag {
            get;
            set;
        }
        public String CustomerNumber {
            get;
            set;
        }
        public String CRMType {
            get;
            set;
        }
        public String CustomerStatus {
            get;
            set;
        }
        public Contract[] Contract {
            get;
            set;
        }
        public String CustomerRowId {
            get;
            set;
        }
    }

    public class CustomerServiceResponseWrapper extends CoreObject {
        public Input Input {
            get;
            set;
        }
        public List<Customer> Customer {
            get;
            set;
        }
    }

    public abstract class CoreObject {
        public Object isFieldExists(String fieldName) {
            String jsonInstance = JSON.serialize(this);
            Map<String, Object> deserializedInstance = (Map<String, Object>) JSON.deserializeUntyped(jsonInstance);
            return (deserializedInstance.get(fieldName) != null);
        }
    }

    public class CampaignElement {
        public String CampaignType;
        public String CampaignFamily;
        public String CampaignNumber;
    }

}