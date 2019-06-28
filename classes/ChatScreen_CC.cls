/*------------------------------------------------------------
Author: Sudipta Karmakar
Company: Salesforce
Description: Controller to get conversation content for supervisors
Inputs:
Test Class:  ChatScreen_CC_Test

History
7/30/18    Sudipta Karmakar    Initial Version.
05.02.2019  Sven Kretschmann    Split class, separate controller for ChatScreen component.
------------------------------------------------------------*/

public with sharing class ChatScreen_CC {
    /*------------------------------------------------------------
    Author:      Sudipta Karmakar
    Company:     Salesforce
    Description: Get data for selected selected session
    Inputs:      SessionId - session Id to find data related to this session
    Returns:     listToSend - serialized data to display for selected session
    Created:     7/30/18
    ------------------------------------------------------------*/
    @AuraEnabled
    public static String getConversationData(String SessionId) {
        List<LiveText__Conversation_Header__c> listToSend = [
            SELECT Id,LiveText__AcceptedBy__r.Name,LiveText__Contact__c,LiveText__Contact__r.Name,CreatedDate,LiveText__SessionReopenedTime__c,LiveText__Originating_Number__c,LiveText__Support_Number__c,LiveText__Account__c, (
                SELECT Id,LiveText__Message__c,LiveText__Sent_To_Customer__c,CreatedBy.Name,CreatedDate
                FROM LiveText__SMS_Text__r
                WHERE LiveText__Source__c != 'Salesforce Linking'
                ORDER BY CreatedDate
            )
            FROM LiveText__Conversation_Header__c
            WHERE Id = :SessionId
        ];

        return JSON.serialize(listToSend);
    }

    /*------------------------------------------------------------
    Author:      Sudipta Karmakar
    Company:     Salesforce
    Description: Get sms content
    Inputs:      smsId - id of sms object to get sms data
    Returns:     string serialized sms content
    ------------------------------------------------------------*/
    @AuraEnabled
    public static String getSmsData(Id smsId) {
        return JSON.serialize([SELECT Id,LiveText__Message__c,LiveText__Sent_To_Customer__c,CreatedBy.Name,CreatedDate FROM LiveText__SMS_Text__c WHERE LiveText__Source__c != 'Salesforce Linking' AND Id = :smsId ORDER BY CreatedDate]);
    }
}