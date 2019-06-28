/*------------------------------------------------------------
Author: Sven Kretschmann
Company: Salesforce
Description: Test class for GroupMemberUtil

Tests executed:
             1 - testGetPublicGroupsForMemberWithDirectMembership()
             Assure the method returns the public groups the user is directly in
             2 - testGetPublicGroupsForMemberWithRoleMembership()
             Assure the method returns the public groups the users role is in
             3 - testGetPublicGroupsForMemberWithNonInheritedAncestorRoleMembership()
             Assure the method returns no public groups where an ancestor of the users role is in without inheritance
             4 - testGetPublicGroupsForMemberWithAncestorRoleMembership()
             Assure the method returns public groups where an ancestor of the users role is in with inheritance
             5 - testGetPublicGroupsForMemberWithPublicGroupMembership()
             Assure the method returns the public groups a public group is member of where the user is member of
             6 - testGetQueuesForMember()
             Assure the method returns the queues the user is directly in
             7 - testGetMemberIdsForGroup
             Assure the method returns all direct and indirect members of the group

History
01.02.2019  Sven Kretschmann    Initial version
------------------------------------------------------------*/
@IsTest
public with sharing class GroupMemberUtil_Test {

    @IsTest
    public static void testGetPublicGroupsForMemberWithDirectMembership() {
        User u = TestDataFactory.createActiveUser();

        List<Group> groups = new List<Group>{
            new Group(
                Name = 'Test Group',
                DeveloperName = 'TestGroup'
            ),
            new Group(
                Name = 'Test Group2',
                DeveloperName = 'TestGroup2'
            )
        };

        insert groups;

        GroupMember membership = new GroupMember(
            UserOrGroupId = u.Id,
            GroupId = groups[0].Id
        );

        insert membership;

        Test.startTest();
        List<Group> actualGroups = GroupMemberUtil.getPublicGroupsForMember(u.Id);
        Test.stopTest();

        System.assertEquals(1, actualGroups.size());
        System.assertEquals(groups[0].Id, actualGroups[0].Id);
    }

    @IsTest
    public static void testGetPublicGroupsForMemberWithRoleMembership() {
        User u = TestDataFactory.createActiveUser();
        UserRole r = [SELECT Id FROM UserRole WHERE ParentRoleId = NULL LIMIT 1];

        u.UserRoleId = r.Id;
        update u;

        /* The role could already be assigned, we need to regard this */
        Set<Group> existingGroups = getRoleMemberships(r);

        Group roleGroup = [SELECT Id FROM Group WHERE RelatedId = :r.Id AND Type = 'Role' LIMIT 1];

        List<Group> groups = new List<Group>{
            new Group(
                Name = 'Test Group',
                DeveloperName = 'TestGroup'
            ),
            new Group(
                Name = 'Test Group2',
                DeveloperName = 'TestGroup2'
            )
        };

        insert groups;

        GroupMember membership = new GroupMember(
            UserOrGroupId = roleGroup.Id,
            GroupId = groups[0].Id
        );

        insert membership;

        Test.startTest();
        List<Group> actualGroups = GroupMemberUtil.getPublicGroupsForMember(u.Id);
        Test.stopTest();

        System.debug(actualGroups);

        System.assertEquals(existingGroups.size() + 1, actualGroups.size());

        Boolean foundGroup = false;
        for (Group actualGroup : actualGroups) {
            if (actualGroup.Id == groups[0].Id) {
                foundGroup = true;
                break;
            }
        }

        System.assert(foundGroup, 'Expected the user to be member of the test group via role membership');
    }

    @IsTest
    public static void testGetPublicGroupsForMemberWithNonInheritedAncestorRoleMembership() {
        User u = TestDataFactory.createActiveUser();
        UserRole parentRole = [SELECT Id FROM UserRole WHERE ParentRoleId = NULL LIMIT 1];
        UserRole assignedRole = [SELECT Id FROM UserRole WHERE ParentRoleId = :parentRole.Id LIMIT 1];

        u.UserRoleId = assignedRole.Id;
        update u;

        /* The role could already be assigned, we need to regard this */
        Set<Group> existingGroups = getRoleMemberships(parentRole);

        Group roleGroup = [SELECT Id FROM Group WHERE RelatedId = :parentRole.Id AND Type = 'Role' LIMIT 1];

        List<Group> groups = new List<Group>{
            new Group(
                Name = 'Test Group',
                DeveloperName = 'TestGroup'
            ),
            new Group(
                Name = 'Test Group2',
                DeveloperName = 'TestGroup2'
            )
        };

        insert groups;

        GroupMember membership = new GroupMember(
            UserOrGroupId = roleGroup.Id,
            GroupId = groups[0].Id
        );

        insert membership;

        Test.startTest();
        List<Group> actualGroups = GroupMemberUtil.getPublicGroupsForMember(u.Id);
        Test.stopTest();

        System.debug(actualGroups);

        Map<Id, Group> skipExistingGroups = new Map<Id, Group>(new List<Group>(existingGroups));

        System.assertEquals(existingGroups.size(), actualGroups.size());
        for (Group actualGroup : actualGroups) {
            skipExistingGroups.remove(actualGroup.Id);
        }

        System.assert(skipExistingGroups.isEmpty());
    }

    @IsTest
    public static void testGetPublicGroupsForMemberWithAncestorRoleMembership() {
        User u = TestDataFactory.createActiveUser();
        UserRole parentRole = [SELECT Id FROM UserRole WHERE ParentRoleId = NULL LIMIT 1];
        UserRole assignedRole = [SELECT Id FROM UserRole WHERE ParentRoleId = :parentRole.Id LIMIT 1];

        u.UserRoleId = assignedRole.Id;
        update u;

        /* The role could already be assigned, we need to regard this */
        Set<Group> existingGroups = getRoleMemberships(parentRole);

        Group roleGroup = [SELECT Id FROM Group WHERE RelatedId = :parentRole.Id AND Type = 'RoleAndSubordinates' LIMIT 1];

        List<Group> groups = new List<Group>{
            new Group(
                Name = 'Test Group',
                DeveloperName = 'TestGroup'
            ),
            new Group(
                Name = 'Test Group2',
                DeveloperName = 'TestGroup2'
            )
        };

        insert groups;

        GroupMember membership = new GroupMember(
            UserOrGroupId = roleGroup.Id,
            GroupId = groups[0].Id
        );

        insert membership;

        Test.startTest();
        List<Group> actualGroups = GroupMemberUtil.getPublicGroupsForMember(u.Id);
        Test.stopTest();

        System.debug(actualGroups);

        System.assertEquals(existingGroups.size() + 1, actualGroups.size());
        Boolean foundGroup = false;
        for (Group actualGroup : actualGroups) {
            if (actualGroup.Id == groups[0].Id) {
                foundGroup = true;
                break;
            }
        }

        System.assert(foundGroup, 'Expected the user to be member of the test group via role membership');
    }

    @IsTest
    public static void testGetPublicGroupsForMemberWithPublicGroupMembership() {
        User u = TestDataFactory.createActiveUser();

        List<Group> groups = new List<Group>{
            new Group(
                Name = 'Test Group',
                DeveloperName = 'TestGroup'
            ),
            new Group(
                Name = 'Test Group2',
                DeveloperName = 'TestGroup2'
            )
        };

        insert groups;

        List<GroupMember> memberships = new List<GroupMember>{
            /* TestGroup2 will be member of TestGroup */
            new GroupMember(
                UserOrGroupId = groups[1].Id,
                GroupId = groups[0].Id
            ),
            /* And the user will be member of TestGroup2 */
            new GroupMember(
                UserOrGroupId = u.Id,
                GroupId = groups[1].Id
            )
        };

        insert memberships;

        Test.startTest();
        List<Group> actualGroups = GroupMemberUtil.getPublicGroupsForMember(u.Id);
        Test.stopTest();

        System.assertEquals(2, actualGroups.size());

        Map<Id, Group> testGroups = new Map<Id, Group>(groups);

        for (Group actualGroup : actualGroups) {
            testGroups.remove(actualGroup.Id);
        }

        System.assert(testGroups.isEmpty());
    }

    @IsTest
    public static void testGetQueuesForMember() {
        User u = TestDataFactory.createActiveUser();

        List<QueueSobject> queues = [SELECT Id,QueueId FROM QueueSobject LIMIT 1];

        GroupMember membership = new GroupMember(
            UserOrGroupId = u.Id,
            GroupId = queues[0].QueueId
        );

        insert membership;

        Test.startTest();
        List<Group> actualQueues = GroupMemberUtil.getQueuesForMember(u.Id);
        Test.stopTest();

        System.debug(actualQueues);
        System.assertEquals(1, actualQueues.size());
        System.assertEquals(queues[0].QueueId, actualQueues[0].Id);
    }

    @IsTest
    public static void testGetMemberIdsForGroup() {
        List<User> testUsers = new List<User>{
            /* direct member */
            TestDataFactory.createActiveUser(),
            /* member by public group */
            TestDataFactory.createActiveUser(),
            /* member by role */
            TestDataFactory.createActiveUser(),
            /* member by child role */
            TestDataFactory.createActiveUser()
        };

        testUsers[0].FirstName = 'User 1';
        testUsers[1].FirstName = 'User 2';
        testUsers[2].FirstName = 'User 3';
        testUsers[3].FirstName = 'User 4';

        UserRole parentRole = [SELECT Id FROM UserRole WHERE ParentRoleId = NULL LIMIT 1];
        UserRole childRole = [SELECT Id FROM UserRole WHERE ParentRoleId = :parentRole.Id LIMIT 1];

        testUsers[2].UserRoleId = childRole.Id;
        testUsers[3].UserRoleId = childRole.Id;

        update testUsers;

        List<Group> groups = new List<Group>{
            new Group(
                Name = 'Test Group',
                DeveloperName = 'TestGroup'
            ),
            new Group(
                Name = 'Test Group2',
                DeveloperName = 'TestGroup2'
            )
        };

        insert groups;

        List<GroupMember> memberships = new List<GroupMember>{
            /* User 1, direct member */
            new GroupMember(
                UserOrGroupId = testUsers[0].Id,
                GroupId = groups[0].Id
            ),
            /* User 2, member by public group, part 1 */
            new GroupMember(
                UserOrGroupId = groups[1].Id,
                GroupId = groups[0].Id
            ),
            /* User 2, member by public group, part 2 */
            new GroupMember(
                UserOrGroupId = testUsers[1].Id,
                GroupId = groups[1].Id
            )
        };

        List<Group> roleGroups = [
            SELECT
                Id
            FROM
                Group
            WHERE
            (
                /* User 3, member by role */
                RelatedId = :childRole.Id
                AND
                Type = 'Role'
            )
            OR
            (
                /* User 4, member by parent role */
                RelatedId = :parentRole.Id
                AND
                Type = 'RoleAndSubordinates'
            )
        ];

        for (Group roleGroup : roleGroups) {
            memberships.add(new GroupMember(
                UserOrGroupId = roleGroup.Id,
                GroupId = groups[0].Id
            ));
        }

        insert memberships;

        Test.startTest();
        List<Id> userIds = GroupMemberUtil.getMemberIdsForGroup(groups[0].Id);

        System.debug(testUsers);
        System.debug(userIds);

        /* Due to the roles the group may contain more users than we set up */
        System.assert(userIds.size() >= 4);

        for (User u : testUsers) {
            System.assert(userIds.contains(u.Id), 'Expected user ' + u.FirstName + ' to be member of the TestGroup');
        }
    }

    /**
     * Retrieve the groups a role is member of.
     *
     * @param r The role to become member
     */
    private static Set<Group> getRoleMemberships(UserRole r) {
        Map<Id, Group> relatedGroups = new Map<Id, Group>([SELECT Id, DeveloperName, Type FROM Group WHERE RelatedId = :r.Id]);
        List<GroupMember> roleMemberships = [SELECT Id, GroupId, Group.Id, Group.Name, Group.DeveloperName FROM GroupMember WHERE UserOrGroupId IN :relatedGroups.keySet()];

        Set<Group> existingGroups = new Set<Group>();

        for (GroupMember member : roleMemberships) {
            existingGroups.add(member.Group);
        }

        System.debug('Found role in group members');
        System.debug(relatedGroups);
        System.debug(roleMemberships);
        System.debug(existingGroups);

        return existingGroups;
    }
}