/*------------------------------------------------------------
Author: Pavel Usoltsev
Company: Salesforce
Description: A utility class for the Live message session trigger
Inputs:      triggeredSMSTexts object values before trigger event
Test Class:  LiveMessageSessionHandler_Test

History
7/12/18    Pavel Usoltsev    Initial Version.
01/23/18   Pavel Kalinin     fix of MOS-246
01/29/18   Pavel Kalinin     implemented MOS-230/MOS-231 stories
02/14/19   Pavel Kalinin     fixed MOS-414 bug
02/15/19   Sven Kretschmann  fixed MOS-416, when taking the queue id from the case, set the owner as well
02/18/19   Pavel Kalinin     fixed MOS-439 bug
02/21/19   Pavel Kalinin     fixed MOS-445 bug (added logic to reopen a case for an active session - reopenRelatedCases())
26.02.2019 Sven Kretschmann  Set the Case.UsedLiveMessageNo if it not yet set
17.04.2019 Stefano Pramparo  fixed MOS-523/INC0308876
------------------------------------------------------------*/

public with sharing class LiveMessageSessionHandler extends TriggerHandler {

    @TestVisible
    private static final String CASE_STATUS_AFTER_SESSION_END = 'Waiting for Customer';
    @TestVisible
    private static final String CASE_STATUS_AFTER_SESSION_START = 'Open';

    private static final String CASE_STATUS_WAITING_FOR_TRANSFER = 'Waiting for Transfer';

    public LiveMessageSessionHandler() {
        this.setMaxLoopCount(20);
    }

    protected override void beforeInsert() {
        checkUpdateIfContactCaseExist();
        assignSessions();
    }

    protected override void afterInsert() {
        //assignDirectlyToAgent();
        updateRelatedCases();
    }

    protected override void beforeUpdate() {
        changeStatusRelatedCase();
        transferSession();
        assignSessions();
        processManualAcceptance();
        resetAgentReplyPendingSince();
    }

    protected override void afterUpdate() {
        updateRelatedCases();
    }

    /*------------------------------------------------------------
    Author: Pavel Usoltsev
    Company: Salesforce
    Description: If there are sessions that are active and last agent that worked on it - is present and has capacity
                 to accept another one case - we need to assign
                 this session to this agent
    Inputs: triggered list of session objects
    Returns: void
    ------------------------------------------------------------*/
//    private void assignDirectlyToAgent() {
//        System.debug('LMSH.assign#1: Trying to route new conversations');
//        System.debug(Trigger.new);
//
//        ServiceChannel channel = this.loadServiceChannel('LiveMessageLv1');
//
//        if (channel == null) {
//            System.debug('LMSH.assign#2: Required service channel not found, get out');
//            return;
//        }
//
//        /* initialize some maps to identify which agent has lastly worked on the cases assigned to the new sessions */
//        Map<Id, List<Id>> sessionIdsByCaseId = new Map<Id, List<Id>>();
//
//        for (LiveText__Conversation_Header__c session : (List<LiveText__Conversation_Header__c>) Trigger.new) {
//            if (session.LiveText__Account__c != null && session.LiveText__Contact__c != null && session.LiveText__Case__c != null) {
//                this.getListEntryFromIdMap(sessionIdsByCaseId, session.LiveText__Case__c).add(session.Id);
//            }
//        }
//
//        System.debug('LMSH.assign#3: Mapped sessions to cases');
//        System.debug(sessionIdsByCaseId);
//
//        List<Case> cases = [SELECT Id, LastAgent__c FROM Case WHERE Id IN :sessionIdsByCaseId.keySet()];
//
//        Map<Id, List<Id>> sessionsIdsByAgentIds = new Map<Id, List<Id>>();
//
//        for (Case cs : cases) {
//            if (cs.LastAgent__c != null) {
//                this.getListEntryFromIdMap(sessionsIdsByAgentIds, cs.LastAgent__c).addAll(sessionIdsByCaseId.get(cs.Id));
//            }
//        }
//
//        System.debug('LMSH.assign#4: Identified responsible agents (map cases to agents)');
//        System.debug(sessionsIdsByAgentIds);
//
//        /* determine the current workload of these agents... */
//        List<LiveText__Conversation_Header__c> activeSessions = [
//            SELECT
//                Id,
//                LiveText__AcceptedBy__c,
//                LiveText__Status__c
//            FROM
//                LiveText__Conversation_Header__c
//            WHERE
//            LiveText__Status__c = 'Active'
//            AND
//            LiveText__AcceptedBy__c IN :sessionsIdsByAgentIds.keySet()
//        ];
//
//        Map<Id, List<Id>> activeSessionIdsByAgentId = new Map<Id, List<Id>>();
//
//        for (LiveText__Conversation_Header__c session : activeSessions) {
//            this.getListEntryFromIdMap(activeSessionIdsByAgentId, session.LiveText__AcceptedBy__c).add(session.Id);
//        }
//
//        System.debug('LMSH.assign#5: Found active sessions of agents');
//        System.debug(activeSessionIdsByAgentId);
//
//        /* ... and their free capacity and if they're actually online */
//        List<UserServicePresence> userServicePresences = [
//            SELECT
//                Id,
//                UserId,
//                ConfiguredCapacity,
//                User.Name
//            FROM
//                UserServicePresence
//            WHERE
//            IsCurrentState = TRUE
//            AND
//            UserId IN :sessionsIdsByAgentIds.keySet()
//        ];
//
//        System.debug('Found user presences for assigning new message');
//        System.debug(userServicePresences);
//
//        List<AgentWork> agentWorks = new List<AgentWork>();
//
//        /* every active agent with free capacity gets assigned their respective sessions */
//        for (UserServicePresence presence : userServicePresences) {
//            Integer capacity = presence.ConfiguredCapacity;
//            Integer workload = activeSessionIdsByAgentId.containsKey(presence.UserId) ? activeSessionIdsByAgentId.get(presence.UserId).size() : 0;
//
//            System.debug('Agent ' + presence.User.Name + ' works ' + workload + ' / ' + capacity);
//
//            for (Id sessionId : sessionsIdsByAgentIds.get(presence.UserId)) {
//                if (workload++ > capacity) {
//                    break;
//                }
//
//                agentWorks.add(new AgentWork(
//                    UserId = presence.UserId,
//                    WorkItemId = sessionId,
//                    ServiceChannelId = channel.Id
//                ));
//            }
//        }
//
//        System.debug('>>> agentWorks = ' + agentWorks);
//
//        insert agentWorks;
//    }

    /*------------------------------------------------------------
     Author: Pavel Usoltsev
     Company: Salesforce
     Description: Check existing contacts, accounts and cases and attach it to the current session
     Inputs: triggered list of session objects
     Returns: void
     ------------------------------------------------------------*/
    private void checkUpdateIfContactCaseExist() {

        Map<String, LiveText__Conversation_Header__c> newEmptySessions = new Map<String, LiveText__Conversation_Header__c>();

        for (LiveText__Conversation_Header__c session : (List<LiveText__Conversation_Header__c>) Trigger.new) {
            if ((session.LiveText__Status__c == 'New' || session.LiveText__Status__c == 'Active') && (session.LiveText__Account__c == null || session.LiveText__Contact__c == null || session.LiveText__Case__c == null)) {
                newEmptySessions.put(session.LiveText__Originating_Number__c, session);
            }
        }

        List<Case> cases = [SELECT Id, CaseNumber, Contact.Phone, Contact.AccountId, Contact.FacebookId__c FROM Case WHERE (Contact.Phone IN :newEmptySessions.keySet() OR Contact.FacebookId__c IN :newEmptySessions.keySet()) AND Status IN ('Open', 'Waiting for Customer')];
        Map<String, Case> phoneCases = new Map<String, Case>();

        for (Case cs : cases) {

            phoneCases.put(cs.Contact.Phone, cs);
            phoneCases.put(cs.Contact.FacebookId__c, cs);

        }

        for (String oKey : newEmptySessions.keySet()) {
            if (phoneCases.containsKey(oKey)) {
                System.debug('Assign case ' + phoneCases.get(oKey).CaseNumber + ' to conversation ' + newEmptySessions.get(oKey).Name);

                newEmptySessions.get(oKey).LiveText__Account__c = phoneCases.get(oKey).Contact.AccountId;
                newEmptySessions.get(oKey).LiveText__Contact__c = phoneCases.get(oKey).ContactId;
                newEmptySessions.get(oKey).LiveText__Case__c = phoneCases.get(oKey).Id;
            }
        }
    }

    /*------------------------------------------------------------
    Author: Pavel Usoltsev
    Company: Salesforce
    Description: change status for the related case if session is ended
                 this session to this agent
    Inputs: triggered list of session objects
    Returns: void
    ------------------------------------------------------------*/
    private void changeStatusRelatedCase() {

        Set<Id> casesToUpdate = new Set<Id>();

        for (Id sessionId : Trigger.newMap.keySet()) {

            LiveText__Conversation_Header__c newSession = (LiveText__Conversation_Header__c) Trigger.newMap.get(sessionId);
            LiveText__Conversation_Header__c oldSession = (LiveText__Conversation_Header__c) Trigger.oldMap.get(sessionId);

            if (newSession.LiveText__Status__c != oldSession.LiveText__Status__c
                    && newSession.LiveText__Status__c == 'Ended'
                    && String.isBlank(newSession.Transfer_To_Queue__c)) {

                casesToUpdate.add(newSession.LiveText__Case__c);
            }

        }

        List<Case> cases = [SELECT Id FROM Case WHERE Id IN :casesToUpdate];

        for (Case cs : cases) {
            cs.Status = CASE_STATUS_AFTER_SESSION_END;
            cs.WaitingForCustomer__c = Datetime.now();
        }

        update cases;
    }

    /*------------------------------------------------------------
    Author:      Pavel Kalinin
    Company:     Salesforce
    Description: handle session transfering:
                 - assign session to appropriate queue
                 - set AcceptedBy field with id of the new cs agent
    Inputs:      triggered list of session objects
    Returns:     void
    ------------------------------------------------------------*/
    private void transferSession() {
        for (LiveText__Conversation_Header__c session : (List<LiveText__Conversation_Header__c>) Trigger.new) {
            //assign session to appropriate queue
            //that was implemented to avoid all async updates:
            //in a frontend we close a session's tab and package automatically closes the session
            //here we make the session active again and assign it to selected queue
            if (session.LiveText__Status__c == 'Ended' && String.isNotBlank(session.Transfer_To_Queue__c)) {
                session.LiveText__Status__c = 'Active';
                session.OwnerId = session.Transfer_To_Queue__c;
                session.Transfer_To_Queue__c = null;
            } else if (session.LiveText__Status__c == 'Ended' && session.Logout__c == true) {
                session.LiveText__Status__c = 'Active';
            }
        }
    }

    /*------------------------------------------------------------
    Author:      Pavel Kalinin
    Company:     Salesforce
    Description: assign sessions to appropriate queues
    Inputs:      triggered list of session objects
    Returns:     void
    ------------------------------------------------------------*/
    private void assignSessions() {
        Map<String, String> queueConfigurations = new Map<String, String>();

        for (LiveMessage_Session_Assignment_Setting__mdt setting : [
                SELECT Id, SupportOption__c, IsRetention__c, QueueAPIName__c
                FROM LiveMessage_Session_Assignment_Setting__mdt
                WHERE IsTest__c = :Test.isRunningTest()
        ]) {

            queueConfigurations.put(setting.SupportOption__c + String.valueOf(setting.IsRetention__c), setting.QueueAPIName__c);
        }

        System.debug('Queue Routing configurations');
        System.debug(queueConfigurations);

        Map<String, Group> queues = new Map<String, Group>();

        for (Group queue : [SELECT Id, Name, DeveloperName FROM Group WHERE Type = 'Queue' AND DeveloperName IN :queueConfigurations.values()]) {
            queues.put(queue.DeveloperName, queue);
        }

        System.debug('Respective queues');
        System.debug(queues);

        Set<Id> casesIds = new Set<Id>();
        List<LiveText__Conversation_Header__c> newSessions = new List<LiveText__Conversation_Header__c>();
        for (LiveText__Conversation_Header__c session : (List<LiveText__Conversation_Header__c>) Trigger.new) {
            if (session.LiveText__Status__c != 'New'
                    || !String.isBlank(session.ResponsibleAgencyId__c)
                    || String.isBlank(session.LiveText__Account__c)
                    || String.isBlank(session.LiveText__Case__c)) {
                System.debug('Session ' + session.Name + ' (' + session.Id + ') is missing information or already has a responsible agency assigned.');
                System.debug(session);
                continue;
            }

            casesIds.add(session.LiveText__Case__c);
            newSessions.add(session);
        }

        if (casesIds.isEmpty()) {
            return;
        }

        Map<Id, Case> relatedCases = new Map<Id, Case>([
                SELECT Id, SupportOption__c, Is_Retention__c, ResponsibleAgencyId__c, ResponsibleAgency__c, IsClosed
                FROM Case
                WHERE Id IN :casesIds
        ]);

        System.debug('Affected cases (ids, existing cases)');
        System.debug(casesIds);
        System.debug(relatedCases);

        List<Case> casesToUpdate = new List<Case>();

        for (LiveText__Conversation_Header__c session : newSessions) {
            if (!relatedCases.containsKey(session.LiveText__Case__c)) {
                continue;
            }

            Case relatedCase = relatedCases.get(session.LiveText__Case__c);
            String queueKey = relatedCase.SupportOption__c + String.valueOf(relatedCase.Is_Retention__c);
            Group queueToAssign = queues.get(queueConfigurations.get(queueKey));

            if (!String.isBlank(relatedCase.ResponsibleAgencyId__c)) {
                System.debug('Session ' + session.Name + ' (' + session.Id + ') gets the responsible agency (' + relatedCase.ResponsibleAgency__c + ') from the case.');

                session.OwnerId = relatedCase.ResponsibleAgencyId__c;
                session.ResponsibleAgencyId__c = relatedCase.ResponsibleAgencyId__c;
                session.ResponsibleAgency__c = relatedCase.ResponsibleAgency__c;
            } else if (queueToAssign != null) {
                System.debug('Session ' + session.Name + ' (' + session.Id + ') gets the queue ' + queueToAssign.Name + '(' + queueToAssign.Id + ') assigned.');

                session.OwnerId = queueToAssign.Id;
                session.ResponsibleAgencyId__c = queueToAssign.Id;
                session.ResponsibleAgency__c = queueToAssign.Name;

                relatedCase.ResponsibleAgencyId__c = queueToAssign.Id;
                relatedCase.ResponsibleAgency__c = queueToAssign.Name;

                casesToUpdate.add(relatedCase);
            } else {
                System.debug('Session ' + session.Name + ' (' + session.Id + ') has no valid queue key ' + queueKey + ' or no queue configuration exists for it.');
            }
        }

        if (!casesToUpdate.isEmpty()) {
            update casesToUpdate;
        }
    }

    /*------------------------------------------------------------
    Author:      Pavel Kalinin
    Company:     Salesforce
    Description: changes the owner of the sessions after it's manual acceptance
    Inputs:      triggered list of session objects
    Returns:     void
    ------------------------------------------------------------*/
    private void processManualAcceptance() {
        for (LiveText__Conversation_Header__c session : (List<LiveText__Conversation_Header__c>) Trigger.new) {

            LiveText__Conversation_Header__c oldSession = (LiveText__Conversation_Header__c) Trigger.oldMap.get(session.Id);

            Boolean isSessionWasAcceptedManually = oldSession.LiveText__Status__c == 'New'
                    && session.LiveText__Status__c == 'Active'
                    && String.isBlank(oldSession.LiveText__AcceptedBy__c)
                    && String.isNotBlank(session.LiveText__AcceptedBy__c)
                    && session.OwnerId != session.LiveText__AcceptedBy__c;

            if (isSessionWasAcceptedManually) {
                session.OwnerId = session.LiveText__AcceptedBy__c;
            }
        }
    }
    /*------------------------------------------------------------
    Author:      Stefano Pramparo
    Company:     Sky De
    Description: when agent accept chat or transfer_flg reset to false,reset the timer of the last agent's message
                 fix for MOS-523/INC0308876
    Inputs:      triggered list of session objects
    Returns:     void
    ------------------------------------------------------------*/
    private void resetAgentReplyPendingSince() {
        for (LiveText__Conversation_Header__c session : (List<LiveText__Conversation_Header__c>) Trigger.new) {
            LiveText__Conversation_Header__c oldSession = (LiveText__Conversation_Header__c) Trigger.oldMap.get(session.Id);
            if ((!oldSession.LiveText__isAccepted__c && session.LiveText__isAccepted__c) ||
                    (oldSession.Transferred__c && !session.Transferred__c))
                session.AgentReplyPendingSince__c = Datetime.now();
        }
    }

    /*------------------------------------------------------------
    Author:      Pavel Kalinin
    Company:     Salesforce
    Description: reopen a case for an active session
    Inputs:      triggered list of session objects
    Returns:     void
    ------------------------------------------------------------*/
    private void updateRelatedCases() {
        Map<Id, Case> casesToUpdate = new Map<Id, Case>();

        Map<Id, LiveText__Conversation_Header__c> conversationsByCase = new Map<Id, LiveText__Conversation_Header__c>();
        for (LiveText__Conversation_Header__c session : (List<LiveText__Conversation_Header__c>) Trigger.new) {
            if (String.isNotBlank(session.LiveText__Case__c) && session.LiveText__Status__c == 'Active') {
                conversationsByCase.put(
                        session.LiveText__Case__c,
                        session
                );
            }
        }

        if (conversationsByCase.isEmpty()) {
            return;
        }

        System.debug(conversationsByCase);

        List<Case> relatedCases = [
                SELECT
                        Id,
                        Status,
                        OwnerId,
                        UsedLiveMessageNo__c
                FROM
                        Case
                WHERE
                Id IN :conversationsByCase.keySet()
                AND
                IsClosed = FALSE
        ];

        for (Case relatedCase : relatedCases) {
            if (relatedCase.Status == CASE_STATUS_WAITING_FOR_TRANSFER) {
                /* don't update cases that are waiting for transfer, they were properly updated before */
                continue;
            }

            if (relatedCase.Status != CASE_STATUS_AFTER_SESSION_START) {
                relatedCase.Status = CASE_STATUS_AFTER_SESSION_START;
                casesToUpdate.put(relatedCase.Id, relatedCase);
            }

            LiveText__Conversation_Header__c conversation = conversationsByCase.get(relatedCase.Id);

            Id targetOwner = String.isBlank(conversation.LiveText__AcceptedBy__c) ? conversation.OwnerId : conversation.LiveText__AcceptedBy__c;

            if (relatedCase.OwnerId != targetOwner) {
                relatedCase.OwnerId = targetOwner;
                casesToUpdate.put(relatedCase.Id, relatedCase);
            }

            if (!String.isBlank(conversation.LiveText__Support_Number__c) && relatedCase.UsedLiveMessageNo__c != conversation.LiveText__Support_Number__c) {
                relatedCase.UsedLiveMessageNo__c = conversation.LiveText__Support_Number__c;
                casesToUpdate.put(relatedCase.Id, relatedCase);
            }
        }

        if (!casesToUpdate.isEmpty()) {
            update casesToUpdate.values();
        }
    }

    /*------------------------------------------------------------
    Author: Sven Kretschmann
    Company: Salesforce
    Description: Load the service channel with the given name.
    Inputs: the name of the channel
    Returns: ServiceChannel
    ------------------------------------------------------------*/
    private ServiceChannel loadServiceChannel(String channelName) {
        List<ServiceChannel> channels = [SELECT Id FROM ServiceChannel WHERE DeveloperName = :channelName LIMIT 1];

        if (channels.isEmpty()) {
            return null;
        }

        return channels[0];
    }

    /*------------------------------------------------------------
    Author: Sven Kretschmann
    Company: Salesforce
    Description: Ensure the container map has the key and is initialized with a list, if not do so, and return it.
    Inputs: The container map to look for the key
            The key to look for
    Returns: List<Id>
    ------------------------------------------------------------*/
    private List<Id> getListEntryFromIdMap(Map<Id, List<Id>> container, Id key) {
        if (!container.containsKey(key)) {
            container.put(key, new List<Id>());
        }

        return container.get(key);
    }

}