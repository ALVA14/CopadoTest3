/*------------------------------------------------------------
Author: Sudipta Karmakar
Company: Salesforce
Description: Controller to get active session data for supervisors
Inputs:
Test Class:  ChatListToChatClass_Test

History
7/30/18    Sudipta Karmakar    Initial Version.
05.02.2019  Sven Kretschmann    Refactoring, split into two classes to get a dedicated controller for the ChatScreen component
------------------------------------------------------------*/

public with sharing class LiveSessionHeaders_CC {

    /*------------------------------------------------------------
    Author:      Sudipta Karmakar
    Company:     Salesforce
    Description: Get connection data for CometD
    Inputs:
    Returns:     ConfigurationDTO - serialized data to comedD connect
    Created:     7/30/18
    ------------------------------------------------------------*/
    @AuraEnabled
    public static ConfigurationDTO getConfiguration() {
        ConfigurationDTO config = new ConfigurationDTO();
        config.baseUrl = System.Url.getSalesforceBaseUrl().toExternalForm();
        config.sessionId = UserInfo.getSessionId();
        return config;
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
    public static List<QueueDTO> getLiveQueues() {
        /* Only display queues I'm member of */
        Map<Id, Group> queues = new Map<Id, Group>(GroupMemberUtil.getQueuesForMember(UserInfo.getUserId()));

        /*
            We could already return all groups (queues),
            but we need to filter on those that have an assignment to the LiveText__Conversation_Header__c
         */
        List<QueueSobject> queueAssignments = [
            SELECT
                QueueId,
                Queue.Name,
                Queue.DeveloperName,
                SobjectType
            FROM
                QueueSobject
            WHERE
            SobjectType = 'LiveText__Conversation_Header__c'
            AND
            QueueId IN :queues.keySet()
            ORDER BY Queue.Name ASC
        ];

        List<QueueDTO> queueOptions = new List<QueueDTO>();

        for (QueueSobject queue : queueAssignments) {
            QueueDTO option = new QueueDTO();
            option.label = queue.Queue.Name;
            option.value = queue.QueueId;
            queueOptions.add(option);
        }

        return queueOptions;
    }

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

        System.debug('Existing data ' + response);

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
    private static Set<Id> getAgentIds(String queueId) {
        List<Id> memberIds = GroupMemberUtil.getMemberIdsForGroup(queueId);

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

    public class ConfigurationDTO {
        @AuraEnabled
        public String sessionId;
        @AuraEnabled
        public String baseUrl ;

    }
    public class QueueDTO {
        @AuraEnabled
        public String label;
        @AuraEnabled
        public String value;

    }
}