/*------------------------------------------------------------
Author: Sven Kretschmann
Company: Salesforce
Description: Provide methods to query the groups a user is member of or to get all members of a given group
Inputs:
Test Class:  GroupMemberUtil_Test

History
01.02.2019  Sven Kretschmann    Initial version
------------------------------------------------------------*/
public without sharing class GroupMemberUtil {

    private static final String GROUP_TYPE_PUBLIC = 'Regular';
    private static final String GROUP_TYPE_QUEUE = 'Queue';
    private static final String GROUP_TYPE_ROLE = 'Role';
    private static final String GROUP_TYPE_ROLE_AND_SUBORDINATES = 'RoleAndSubordinates';
    private static final String GROUP_TYPE_ROLE_AND_SUBORDINATES_INTERNAL = 'RoleAndSubordinatesInternal';

    /*------------------------------------------------------------
    Author: Sven Kretschmann
    Company: Salesforce
    Description: Get all public groups the given user is member of
    Inputs: userId The id of the user
    Returns: The groups the user is member of, either directly or indirectly

    History
    05.02.2019  Sven Kretschmann    Initial Version.
    ------------------------------------------------------------*/
    public static List<Group> getPublicGroupsForMember(Id userId) {
        return getGroupsForMember(userId, GROUP_TYPE_PUBLIC);
    }

    /*------------------------------------------------------------
    Author: Sven Kretschmann
    Company: Salesforce
    Description: Get all queues the given user is member of
    Inputs: userId      The id of the user
    Returns: The queues the user is member of, either directly or indirectly

    History
    05.02.2019  Sven Kretschmann    Initial Version.
    ------------------------------------------------------------*/
    public static List<Group> getQueuesForMember(Id userId) {
        return getGroupsForMember(userId, GROUP_TYPE_QUEUE);
    }

    /*------------------------------------------------------------
    Author: Sven Kretschmann
    Company: Salesforce
    Description: Get all user ids of the members of the given groups.
                 Resolves indirect memberships of roles and public groups
    Inputs: groupId      The id of the group or queue
    Returns: The user ids of the members

    History
    05.02.2019  Sven Kretschmann    Initial Version.
    ------------------------------------------------------------*/
    public static List<Id> getMemberIdsForGroup(Id groupId) {
        return new List<Id>(getMemberIdsForGroups(new Set<Id>{
            groupId
        }));
    }

    private static List<Group> getGroupsForMember(Id userId, String type) {
        /* regard role & subordinates */
        /* regard public groups */

        User userData = [SELECT Id, UserRoleId FROM User WHERE Id = :userId];

        List<Id> roleGroupIds = new List<Id>();
        if (!String.isBlank(userData.UserRoleId)) {
            roleGroupIds = getRoleAncestorGroupIds(userData.UserRoleId);
        }

        System.debug(userId);
        System.debug(roleGroupIds);

        /* select all groups, regardless of type. We'll need to climb through the public groups later, so we need them anyway*/
        List<GroupMember> memberships = [
            SELECT
                GroupId,
                UserOrGroupId,
                Group.Id,
                Group.Type,
                Group.DeveloperName
            FROM
                GroupMember
            WHERE
            (
                UserOrGroupId = :userId
                OR
                UserOrGroupId IN :roleGroupIds
            )
        ];

        System.debug(memberships);

        Map<Id, Group> groups = new Map<Id, Group>();

        populateGroupMapFromMemberships(groups, memberships, type);

        return groups.values();
    }

    private static List<Id> getRoleAncestorGroupIds(Id roleId) {
        List<Id> roleIds = getRoleAncestorIds(roleId);

        Map<Id, Group> roleGroups = new Map<Id, Group>([
            SELECT Id, RelatedId
            FROM Group
            WHERE (
                RelatedId IN :roleIds
                AND
                Type IN (:GROUP_TYPE_ROLE_AND_SUBORDINATES, :GROUP_TYPE_ROLE_AND_SUBORDINATES_INTERNAL)
            )
            OR
            (
                RelatedId = :roleId
            )
        ]);

        return new List<Id>(roleGroups.keySet());
    }

    private static List<Id> getRoleAncestorIds(Id roleId) {
        List<Id> ancestorIds = new List<Id>();
        ancestorIds.add(roleId);

        UserRole role = [SELECT Id, ParentRoleId FROM UserRole WHERE Id = :roleId];

        if (!String.isBlank(role.ParentRoleId)) {
            ancestorIds.addAll(getRoleAncestorIds(role.ParentRoleId));
        }

        return ancestorIds;
    }

    private static Set<Id> getRoleDescendantIds(Set<Id> parentRoleIds) {
        Set<Id> descendantIds = new Set<Id>();
        descendantIds.addAll(parentRoleIds);

        Map<Id, UserRole> childRoles = new Map<Id, UserRole>([SELECT Id, ParentRoleId FROM UserRole WHERE ParentRoleId IN :parentRoleIds]);

        if (!childRoles.isEmpty()) {
            descendantIds.addAll(getRoleDescendantIds(childRoles.keySet()));
        }

        return descendantIds;
    }

    private static void populateGroupMapFromMemberships(Map<Id, Group> groups, List<GroupMember> memberships, String targetGroupType) {
        Set<Id> publicGroupIds = new Set<Id>();

        for (GroupMember member : memberships) {
            if (member.Group.Type == targetGroupType && !groups.containsKey(member.GroupId)) {
                groups.put(member.GroupId, member.Group);
            }

            if (member.Group.Type == GROUP_TYPE_PUBLIC) {
                /* remember the public groups, we'll need to query all groups they are members of */
                publicGroupIds.add(member.GroupId);
            }
        }

        if (!publicGroupIds.isEmpty()) {
            /* there are some more public groups to query */
            populateGroupMapFromMemberships(groups, getMembershipsByMembers(new List<Id>(publicGroupIds)), targetGroupType);
        }
    }

    private static List<GroupMember> getMembershipsByMembers(List<Id> memberIds) {
        return [
            SELECT
                GroupId,
                UserOrGroupId,
                Group.Id,
                Group.Type,
                Group.DeveloperName
            FROM
                GroupMember
            WHERE
                UserOrGroupId IN :memberIds
        ];
    }

    /**
     * Get all users ids of the given groups, regardless of where they are member. Used internally
     * to more efficently resolve nested memberships of public groups.
     *
     * @param groupIds
     *
     * @return
     */
    private static Set<Id> getMemberIdsForGroups(Set<Id> groupIds) {
        Set<Id> ids = new Set<Id>();

        List<GroupMember> directMembers = [SELECT UserOrGroupId FROM GroupMember WHERE GroupId IN :groupIds];
        List<Id> memberGroupIds = new List<Id>();

        for (GroupMember member : directMembers) {
            if (member.UserOrGroupId.getSobjectType() == User.getSObjectType()) {
                ids.add(member.UserOrGroupId);
            } else {
                memberGroupIds.add(member.UserOrGroupId);
            }
        }

        if (!memberGroupIds.isEmpty()) {
            Set<Id> publicGroupIds = new Set<Id>();
            Set<Id> roleIds = new Set<Id>();

            List<Group> groups = [SELECT Id, Type, RelatedId FROM Group WHERE Id IN :memberGroupIds];

            for (Group g : groups) {
                if (g.Type == GROUP_TYPE_PUBLIC) {
                    publicGroupIds.add(g.Id);
                } else if (g.Type == GROUP_TYPE_ROLE) {
                    roleIds.add(g.RelatedId);
                } else if (g.Type == GROUP_TYPE_ROLE_AND_SUBORDINATES_INTERNAL || g.Type == GROUP_TYPE_ROLE_AND_SUBORDINATES) {
                    roleIds.addAll(getRoleDescendantIds(new Set<Id>{g.RelatedId}));
                }
            }

            if (!publicGroupIds.isEmpty()) {
                ids.addAll(getMemberIdsForGroups(publicGroupIds));
            }

            if (!roleIds.isEmpty()) {
                Map<Id, User> usersInRole = new Map<Id, User>([SELECT Id FROM User WHERE UserRoleId IN :roleIds]);
                ids.addAll(usersInRole.keySet());
            }
        }

        return ids;
    }
}