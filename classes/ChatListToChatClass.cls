/*------------------------------------------------------------
Author: Sudipta Karmakar
Company: Salesforce
Description: Controller to get active session data for supervisors
Inputs:
Test Class:  ChatListToChatClass_Test

History
7/30/18    Sudipta Karmakar    Initial Version.
------------------------------------------------------------*/

public with sharing class ChatListToChatClass {

    /*------------------------------------------------------------
    Author:      Sudipta Karmakar
    Company:     Salesforce
    Description: Get active sessions by accepted user
    Inputs:      queueId - String id of the queue to get active sessions for this queue
    Returns:     mapToGroupAllLiveTexts - map of sessions grouped by accepted user
    Created:     7/30/18
    ------------------------------------------------------------*/
    @AuraEnabled
    public static Map <String, List <LiveText__Conversation_Header__c>> getActiveSessions(String queueId) {
        System.debug('GET ID: ' + queueId);

        Map <String, List <LiveText__Conversation_Header__c>> conversations = new Map <String, List <LiveText__Conversation_Header__c>>();

        Set<Id> memberIds = getAgentIds(queueId);

        hydrateConversationMap(conversations, [
            SELECT
                Id,
                LiveText__AcceptedBy__c,
                LiveText__AcceptedBy__r.Name,
                LiveText__Case__c,
                LiveText__Case__r.CaseNumber,
                LiveText__LiveText_Number__c,
                LiveText__Contact__c,
                LiveText__Contact__r.Name,
                LiveText__Status__c,
                Name
            FROM
                LiveText__Conversation_Header__c
            WHERE
            LiveText__Status__c = 'Active'
            AND
            LiveText__AcceptedBy__c IN :memberIds
        ]);

        return conversations;
    }

    /*------------------------------------------------------------
    Author:      Sudipta Karmakar
    Company:     Salesforce
    Description: Get all queues to populate in combobox for selection active queue
    Inputs:
    Returns:     queueOptions - serialized options for queue combobox
    Created:     7/30/18
    ------------------------------------------------------------*/
    @AuraEnabled
    public static List<JsonWrapQueueOption> getLiveQueues() {
        String userId = UserInfo.getUserId();

        /* Only display queues I'm member of */
        List<GroupMember> memberships = [SELECT GroupId FROM GroupMember WHERE UserOrGroupId = :userId AND Group.Type = 'Queue'];

        Set<Id> relevantGroupIds = new Set<Id>();

        for (GroupMember member : memberships) {
            relevantGroupIds.add(member.GroupId);
        }

        List<QueueSobject> queues = [
            SELECT
                QueueId,
                Queue.Name
            FROM
                QueueSobject
            WHERE
            SobjectType = 'LiveText__Conversation_Header__c'
            AND
            QueueId IN :relevantGroupIds
            ORDER BY Queue.Name ASC
        ];

        List<JsonWrapQueueOption> queueOptions = new List<JsonWrapQueueOption>();

        for (QueueSobject queue : queues) {
            JsonWrapQueueOption option = new JsonWrapQueueOption();
            option.label = queue.Queue.Name;
            option.value = queue.QueueId;
            queueOptions.add(option);
        }

        return queueOptions;
    }

    /*------------------------------------------------------------
    Author:      Sudipta Karmakar
    Company:     Salesforce
    Description: Get data for selected selected session
    Inputs:      SessionId - session Id to find data related to this session
    Returns:     listToSend - serialized data to display for selected session
    Created:     7/30/18
    ------------------------------------------------------------*/
    @AuraEnabled
    public static String getActiveSessionsData(String SessionId) {
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
    Description: Get connection data for CometD
    Inputs:
    Returns:     oJsonWrap - serialized data to comedD connect
    Created:     7/30/18
    ------------------------------------------------------------*/
    @AuraEnabled
    public static String getBaseAndSession() {
        JsonWrap oJsonWrap = new JsonWrap();
        oJsonWrap.strBaseUrl = System.Url.getSalesforceBaseUrl().toExternalForm();
        oJsonWrap.strSessionId = UserInfo.getSessionId();
        return JSON.serialize(oJsonWrap);
    }

    /*------------------------------------------------------------
    Author:      Sudipta Karmakar
    Company:     Salesforce
    Description: Get sms content
    Inputs:      smsId - id of sms object to get sms data
    Returns:     string serialized sms content
    ------------------------------------------------------------*/
    @AuraEnabled
    public static String getSmsData(String smsId) {
        System.debug('The SMSID' + smsId);
        return JSON.serialize([SELECT Id,LiveText__Message__c,LiveText__Sent_To_Customer__c,CreatedBy.Name,CreatedDate FROM LiveText__SMS_Text__c WHERE LiveText__Source__c != 'Salesforce Linking' AND Id = :smsId ORDER BY CreatedDate]);
    }

    /*------------------------------------------------------------
    Author:      Sudipta Karmakar
    Company:     Salesforce
    Description: Get data for selected selected session
    Inputs:      SessionId - session Id to find data related to this session
                 selectedQueue - selected queue
                 response - received sessions
    Returns:     mapToGroupAllLiveTexts - serialized map of session accepted by the selected user
    Created:     7/30/18
    ------------------------------------------------------------*/
    @AuraEnabled
    public static Map <String, List <LiveText__Conversation_Header__c>> getNewActiveSessions(String sessionId, String response, String selectedQueue) {
        Set<Id> memberIds = getAgentIds(selectedQueue);

        System.debug('The Dta ' + response);
        Map <String, List <LiveText__Conversation_Header__c>> conversations =
            (Map <String, List <LiveText__Conversation_Header__c>>) JSON.deserialize(response, Map <String, List <LiveText__Conversation_Header__c>>.class);

        System.debug('I hope We get it ' + conversations);

        hydrateConversationMap(conversations, [
            SELECT
                Id,
                LiveText__AcceptedBy__c,
                LiveText__AcceptedBy__r.Name,
                LiveText__Case__c,
                LiveText__Case__r.CaseNumber,
                LiveText__LiveText_Number__c,
                LiveText__Contact__c,
                LiveText__Contact__r.Name,
                LiveText__Status__c,
                Name
            FROM
                LiveText__Conversation_Header__c
            WHERE
            Id = :sessionId
            AND
            LiveText__Status__c = 'Active'
            AND
            LiveText__AcceptedBy__c IN :memberIds
        ]);

        return conversations;
    }

    /**
     * Load the member ids of the given queue. Filtered by users that share the same division as the current user.
     *
     * @param queueId
     *
     * @return
     */
    public static Set<Id> getAgentIds(String queueId) {
        List<GroupMember> members = [SELECT GroupId, UserOrGroupId, Id, Group.Name FROM GroupMember WHERE GroupId = :queueId];

        Set<Id> memberIds = new Set<Id>();
        for (GroupMember member : members) {
            memberIds.add(member.UserOrGroupId);
        }

        User currentUser = [SELECT Id, Division FROM User WHERE Id = :UserInfo.getUserId()];

        Map<Id, User> filteredUsers = new Map<Id, User>([SELECT Id, Division FROM User WHERE Id IN :memberIds AND Division = :currentUser.Division]);
        Set<Id> filteredMemberIds = new Set<Id>();

        for (Id memberId : memberIds) {
            if (filteredUsers.containsKey(memberId)) {
                filteredMemberIds.add(memberId);
            }
        }

        System.debug('MEMBERS: ' + filteredMemberIds);

        return filteredMemberIds;
    }

    /**
     * Hydrate the map with the conversations, owning agent is the key of the map.
     *
     * @param conversationMap
     * @param conversations
     */
    private static void hydrateConversationMap(Map<String, List<LiveText__Conversation_Header__c>> conversationMap, List<LiveText__Conversation_Header__c> conversations) {
        for (LiveText__Conversation_Header__c conversation : conversations) {
            if (conversationMap.containsKey(conversation.LiveText__AcceptedBy__c)) {
                conversationMap.get(conversation.LiveText__AcceptedBy__c).add(conversation);
            } else {
                conversationMap.put(conversation.LiveText__AcceptedBy__c, new List<LiveText__Conversation_Header__c>{
                    conversation
                });
            }
        }
    }

    public class JsonWrap {
        @AuraEnabled
        public String strSessionId;
        @AuraEnabled
        public String strBaseUrl ;

    }
    public class JsonWrapQueueOption {
        @AuraEnabled
        public String label;
        @AuraEnabled
        public String value;

    }
}