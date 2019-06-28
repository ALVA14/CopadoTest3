/*------------------------------------------------------------
Author:      Sudipta Karmakar
Company:     Salesforce
Description: A Utility class used in test classes to create Objects
Inputs:

History
8/1/18     Pavel Usoltsev   Initial Version
29.01.2019 Sven Kretschmann getRandomString is now public and won't return a digit as first character.
28.02.2019 Sven Kretschmann Cleanup, remove unused stuff, add createQueue method
------------------------------------------------------------*/
@IsTest
public class TestDataFactory {
    private final static Schema.User RUNNING_USER;
    static {
        RUNNING_USER = [
            SELECT Id
            FROM User
            WHERE Id = :UserInfo.getUserId()
            LIMIT 1
        ];
    }
    private final static Set<String> EXCLUDE_FIELD_NAME = new Set<String>{
        'BusinessHours', 'LastModifiedById', 'LastModifiedId', 'CreatedById', 'SystemModstamp', 'LastModifiedDate', 'CreatedDate', 'ClosedDate', 'ListPrice', 'TotalPrice', 'RecurrenceType', 'RecurrenceTimeZoneSidKey', 'RecurrenceStartDateTime', 'RecurrenceMonthOfYear', 'RecurrenceInterval', 'RecurrenceInstance', 'RecurrenceEndDateOnly', 'RecurrenceDayOfWeekMask', 'RecurrenceDayOfMonth', 'IsRecurrence', 'DurationInMinutes', 'RecurrenceStartDateOnly', 'ConvertedDate'
    };
    private final static Set<String> EXCLUDE_REFERENCE_FIELD_NAME = new Set<String>{
        'BusinessHoursId', 'ForecastUserId', 'UserRoleId', 'CallCenterId'
    };
    private final static Set<String> DIGITS = new Set<String>{
        '0', '1', '2', '3', '4', '5', '6', '7', '8', '9'
    };
    private final static Set<String> EXCLUDE_COMPOUND_FIELD_NAME = new Set<String>{
        'contact_name'
    };
    private final static Set<String> FIELD_TYPE_TEXT = new Set<String>{
        'STRING', 'TEXTAREA', 'PHONE', 'URL', 'ENCRYPTEDSTRING'
    };
    private final static Set<String> FIELD_TYPE_PICKLIST = new Set<String>{
        'MUTIPICKLIST', 'PICKLIST'
    };
    private final static Set<String> FIELD_TYPE_EMAIL = new Set<String>{
        'EMAIL'
    };
    private final static Set<String> FIELD_TYPE_NUMBER = new Set<String>{
        'INTEGER', 'PERCENT', 'DECIMAL', 'DOUBLE', 'CURRENCY'
    };
    private final static Set<String> FIELD_TYPE_TIME = new Set<String>{
        'TIME', 'DATETIME'
    };
    private final static Set<String> FIELD_TYPE_DATE = new Set<String>{
        'DATE'
    };
    private final static Set<String> FIELD_TYPE_BOOLEAN = new Set<String>{
        'BOOLEAN'
    };

    private static String emailValue = 'test@coba.com';
    private static String profileName = 'CMS Publisher Commerzbank Marketing';
    private static String profileId;
    private static Integer numberValue = 90;
    private static Boolean booleanValue = false;
    private static Date dateValue = System.today();
    private static Datetime datetimeValue = System.now();
    private static Boolean insertSObjects = false;
    private static String picklistValue;
    private static Map<String, Schema.SObjectType> globalDescribe;
    private static Map<String, Schema.SObjectField> fieldNamesMap;
    private static SObjectType sobjTyp;
    private static String objName;
    private static Map<String, Map<String, Id>> objNameReferenceNameIdPairs = new Map<String, Map<String, Id>>();
    private static Map<String, String> fieldNameValuePairs = new Map<String, String>();

    /*------------------------------------------------------------
    Author:      Sudipta Karmakar
    Company:     Salesforce
    Description: Creates the field maps for object
    Inputs:      String Object name

    Returns:     void
    ------------------------------------------------------------*/
    private static void init(String objectName) {
        objName = objectName;
        globalDescribe = globalDescribe == null ? Schema.getGlobalDescribe() : globalDescribe;
        sobjTyp = globalDescribe.get(objName);
        if (sobjTyp == null) {
            throw new UnsupportedObjectTypeException('UnsupportedObjectTypeException' + ': ' + objName);
        }
        fieldNamesMap = sobjTyp.getDescribe().fields.getMap();
    }

    /*------------------------------------------------------------
    Author:      Sudipta Karmakar
    Company:     Salesforce
    Description: Creates the Creates the Sobject
    Inputs:      String Objectname

    Returns:sObject
    ------------------------------------------------------------*/
    public static SObject createSObject(String objectName) {
        init(objectName);
        SObject sobj = sobjTyp.newSObject();
        sobj = buildSObject(sobj);
        if (insertSObjects) {
            insert sobj;
        }
        return sobj;
    }

    /*------------------------------------------------------------
    Author:      Sudipta Karmakar
    Company:     Salesforce
    Description: Creates sobject with given field values
    Inputs:      String Objectname

    Returns:     Sobject
    ------------------------------------------------------------*/
    private static SObject buildSObject(SObject sobj) {
        for (Schema.SObjectField fName : fieldNamesMap.values()) {
            Schema.DescribeFieldResult field = fName.getDescribe();
            String compoundField = objName.toLowerCase() + '_' + field.getName().toLowerCase();
            if (EXCLUDE_FIELD_NAME.contains(field.getName()) || EXCLUDE_COMPOUND_FIELD_NAME.contains(compoundField)) {
                continue;
            }

            if (field.isCreateable()) {
                if (field.isExternalId() && field.getType() != Schema.DisplayType.REFERENCE) {
                    sobj.put(field.getName(), getRandomString(7));
                    continue;
                }
            } else {
                continue;
            }

            if (FIELD_TYPE_TEXT.contains(field.getType().name())) {
                if (field.isNillable() && !fieldNameValuePairs.containsKey(field.getName())) {
                    continue;
                }

                if (field.getName().equals('Username') && objName.equals('User')) {
                    sobj.put(field.getName(), getRandomString(7) + emailValue);
                } else {
                    String str = getRandomString(20);
                    Integer endIndex = str.length() >= field.getLength() ? field.getLength() : str.length();
                    sobj.put(field.getName(), str.substring(0, endIndex - 1));
                }
                if (fieldNameValuePairs.containsKey(field.getName()) && (field.isNillable() || String.isNotBlank(fieldNameValuePairs.get(field.getName())))) {
                    sobj.put(field.getName(), fieldNameValuePairs.get(field.getName()));
                }
            } else if (FIELD_TYPE_EMAIL.contains(field.getType().name())) {
                sobj.put(field.getName(), getRandomString(7) + emailValue);
                if (fieldNameValuePairs.containsKey(field.getName()) && String.isNotBlank(fieldNameValuePairs.get(field.getName()))) {
                    sobj.put(field.getName(), fieldNameValuePairs.get(field.getName()));
                }
            } else if (FIELD_TYPE_BOOLEAN.contains(field.getType().name())) {
                sobj.put(field.getName(), booleanValue);
                if (fieldNameValuePairs.containsKey(field.getName()) && String.isNotBlank(fieldNameValuePairs.get(field.getName()))) {
                    sobj.put(field.getName(), Boolean.valueOf(fieldNameValuePairs.get(field.getName())));
                } else if (field.getName().equals('IsConverted')) {
                    sobj.put(field.getName(), false);
                }
            } else if (FIELD_TYPE_NUMBER.contains(field.getType().name())) {
                sobj.put(field.getName(), numberValue);
                if (fieldNameValuePairs.containsKey(field.getName()) && String.isNotBlank(fieldNameValuePairs.get(field.getName()))) {
                    sobj.put(field.getName(), Integer.valueOf(fieldNameValuePairs.get(field.getName())));
                }
            } else if (FIELD_TYPE_TIME.contains(field.getType().name())) {
                sobj.put(field.getName(), Datetime.valueOf(datetimeValue));
                if (fieldNameValuePairs.containsKey(field.getName()) && String.isNotBlank(fieldNameValuePairs.get(field.getName()))) {
                    sobj.put(field.getName(), Datetime.valueOf(fieldNameValuePairs.get(field.getName())));

                }
            } else if (FIELD_TYPE_DATE.contains(field.getType().name())) {
                sobj.put(field.getName(), dateValue);
                if (fieldNameValuePairs.containsKey(field.getName()) && String.isNotBlank(fieldNameValuePairs.get(field.getName()))) {
                    sobj.put(field.getName(), Date.valueOf(fieldNameValuePairs.get(field.getName())));
                }
            } else if (FIELD_TYPE_PICKLIST.contains(field.getType().name())) {
                if (field.isNillable() && !fieldNameValuePairs.containsKey(field.getName())) {
                    continue;
                }
                String plv = picklistValue != null ? picklistValue : field.getPicklistValues()[0].getValue();
                sobj.put(field.getName(), plv);
                if (fieldNameValuePairs.containsKey(field.getName()) && String.isNotBlank(fieldNameValuePairs.get(field.getName()))) {
                    sobj.put(field.getName(), fieldNameValuePairs.get(field.getName()));
                }
            } else if (field.getType() == Schema.DisplayType.REFERENCE) {
                String referenceType = field.getReferenceTo()[0].getDescribe().getName();
                if (fieldNameValuePairs.containsKey(field.getName()) && String.isNotBlank(fieldNameValuePairs.get(field.getName()))) {
                    if (referenceType.equals('RecordType')) {
                        String recordTypeId = getRecordTypeIdByName(fieldNameValuePairs.get(field.getName()));
                        if (recordTypeId == null) {
                            throw new UnavailableRecordTypeException('UnavailableRecordTypeException' + ': ' + fieldNameValuePairs.get(field.getName()));
                        } else {
                            sobj.put(field.getName(), recordTypeId);
                            setObjNameReferenceNameIdPairs(objName, field.getName(), recordTypeId);
                        }
                    } else {
                        sobj.put(field.getName(), fieldNameValuePairs.get(field.getName()));
                        setObjNameReferenceNameIdPairs(objName, field.getName(), fieldNameValuePairs.get(field.getName()));
                    }
                } else {
                    //Map<String, Id> referenceNameIdPairs;
                    if (objNameReferenceNameIdPairs.containsKey(objName) && objNameReferenceNameIdPairs.get(objName).containsKey(field.getName())) {
                        sobj.put(field.getName(), objNameReferenceNameIdPairs.get(objName).get(field.getName()));
                    } else {
                        if (EXCLUDE_REFERENCE_FIELD_NAME.contains(field.getName())) {
                            continue;
                        }
                        if (field.getName().equals('ProfileId')) {
                            sobj.put(field.getName(), getProfileId());
                            continue;
                        }
                        if (referenceType.equals('RecordType')) {
                            if (field.isNillable()) {
                                continue;
                            }
                            String recordTypeId = getDefaultRecordType();
                            sobj.put(field.getName(), recordTypeId);
                            setObjNameReferenceNameIdPairs(objName, field.getName(), recordTypeId);
                        } else if (referenceType.equals('User') || field.getName().equals('DelegatedApproverId')) {
                            sobj.put(field.getName(), UserInfo.getUserId());
                            setObjNameReferenceNameIdPairs(objName, field.getName(), UserInfo.getUserId());
                        } else if (!referenceType.equals(objName) && !field.isNillable()) {
                            String reference = UserInfo.getUserId();
                            sobj.put(field.getName(), reference);
                            setObjNameReferenceNameIdPairs(objName, field.getName(), reference);
                        }
                    }
                }
            }

        }
        return sobj;
    }

    /*------------------------------------------------------------
    Author:      Sudipta Karmakar
    Company:     Salesforce
    Description: Get the default recordtypes of Sobject
    Inputs:      Null

    Returns:     String id of record type
    ------------------------------------------------------------*/
    private static String getDefaultRecordType() {
        String defaultRecordTypeId;
        Schema.SObjectType sst = sobjTyp != null ? sobjTyp : ((globalDescribe != null && objName != null) ? globalDescribe.get(objName) : null);
        if (sst != null) {
            List<Schema.RecordTypeInfo> recordTypes = sst.getDescribe().getRecordTypeInfos();
            if (!recordTypes.isEmpty()) {
                for (Schema.RecordTypeInfo recordTypeInfo : recordTypes) {
                    if (recordTypeInfo.isAvailable() && recordTypeInfo.isDefaultRecordTypeMapping()) {
                        defaultRecordTypeId = recordTypeInfo.getRecordTypeId();
                    }
                }
            }
        }
        return defaultRecordTypeId;
    }

    /*------------------------------------------------------------
    Author:        Sudipta Karmakar
    Company:       Salesforce
    Description:   Get the default recordtypes of by Name
    Inputs:        String Objectname

    Returns:       String id of record type
    ------------------------------------------------------------*/
    private static String getRecordTypeIdByName(String name) {
        String recordTypeId;
        Schema.SObjectType sst = sobjTyp != null ? sobjTyp : ((globalDescribe != null && objName != null) ? globalDescribe.get(objName) : null);
        if (sst != null) {
            Map<String, Schema.RecordTypeInfo> rtMapByName = sst.getDescribe().getRecordTypeInfosByName();
            Schema.RecordTypeInfo rtByName = rtMapByName.containsKey(name) ? rtMapByName.get(name) : null;
            recordTypeId = rtByName != null ? rtByName.getRecordTypeId() : null;
        }
        return recordTypeId;
    }

    /*------------------------------------------------------------
    Author:        Sudipta Karmakar
    Company:       Salesforce
    Description:   Get the default profiles
    Inputs:        String Objectname

    Returns:       String id of Profile
    ------------------------------------------------------------*/
    private static String getProfileId() {
        if (profileId == null) {
            List<Profile> p = [SELECT Id, Name, UserType, UserLicenseId FROM Profile WHERE Name = :profileName LIMIT 1];
            if (p.isEmpty()) {
                p = [SELECT Id, Name, UserType, UserLicenseId FROM Profile WHERE Name = 'Standard User' LIMIT 1];
            }
            profileId = p[0].Id;
        }
        return profileId;
    }

    /*------------------------------------------------------------
    Author:      Sudipta Karmakar
    Company:     Salesforce
    Description: Random String generator
    Inputs:      Size of string

    Returns:     String
    ------------------------------------------------------------*/
    public static String getRandomString(Integer size) {
        final String chars = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789abcdefghijklmnopqrstuvwxyz';

        String randomString = '';
        while (randomString.length() < size) {
            Integer idx = Math.mod(Math.abs(Crypto.getRandomInteger()), chars.length());
            randomString += chars.substring(idx, idx + 1);
        }

        if (DIGITS.contains(randomString.substring(0, 1))) {
            /* in case the first character hit a digit, replace it with 'a', it's ok here */
            return 'a' + randomString.substring(0, size - 1);
        }

        return randomString;
    }

    /*------------------------------------------------------------
    Author:      Sudipta Karmakar
    Company:     Salesforce
    Description: Sets Value set in the map
    Inputs:      String of Fieldname and String of value

    Returns:     Void
    ------------------------------------------------------------*/
    public static void setFieldNameValuePairs(String field, String value) {
        fieldNameValuePairs.put(field, value);
    }

    /*------------------------------------------------------------
    Author:      Sudipta Karmakar
    Company:     Salesforce
    Description: Resets the map of fields and its values
    Inputs:      None

    Returns:     Void
    ------------------------------------------------------------*/
    public static void resetFieldNameValuePairs() {
        fieldNameValuePairs = new Map<String, String>();
    }

    /*------------------------------------------------------------
    Author:      Sudipta Karmakar
    Company:     Salesforce
    Description: Sets Object and Field and its value
    Inputs:      String Object Name, field name and its value

    Returns:     Void
    ------------------------------------------------------------*/
    private static void setObjNameReferenceNameIdPairs(String objectName, String name, String value) {
        Map<String, Id> referenceNameIdPairs;
        if (objNameReferenceNameIdPairs.containsKey(objectName)) {
            referenceNameIdPairs = objNameReferenceNameIdPairs.get(objectName);
            referenceNameIdPairs.put(name, Id.valueOf(value));
        } else {
            referenceNameIdPairs = new Map<String, Id>();
            referenceNameIdPairs.put(name, Id.valueOf(value));
        }
        objNameReferenceNameIdPairs.put(objectName, referenceNameIdPairs);
    }

    /*------------------------------------------------------------
    Author:      Sudipta Karmakar
    Company:     Salesforce
    Description: Sets if the object needs to be inserted
    Inputs:      boolean

    Returns:     Void
    ------------------------------------------------------------*/
    public static void setInsertOBjects(Boolean flag) {
        insertSObjects = flag;
    }

    /*------------------------------------------------------------
    Author:      Sudipta Karmakar
    Company:     Salesforce
    Description: Create active user
    Inputs:      Size of string

    Returns:     String
    ------------------------------------------------------------*/
    /******************************* HELPERS ********************************/
    public static Schema.User getRunningUser() {
        return RUNNING_USER;
    }

    public static User createActiveUser() {
        User testUser;
        TestDataFactory.setFieldNameValuePairs('IsActive', 'true');
        TestDataFactory.setFieldNameValuePairs('UserPermissionsMarketingUser', 'true');
        testUser = (User) TestDataFactory.createSObject('User');
        insert testUser;

        List<PermissionSetAssignment> psas = new List<PermissionSetAssignment>();
        List<PermissionSet> ps = [SELECT Id FROM PermissionSet WHERE Name = 'View_Encrypted_Data' OR Name = 'Approve_Content_to_publish'];

        if (!ps.isEmpty()) {
            for (PermissionSet psfound : ps) {
                PermissionSetAssignment psa = new PermissionSetAssignment(AssigneeId = testUser.Id, PermissionSetId = psfound.Id);
                psas.add(psa);
            }
        }

        if (!psas.isEmpty()) {
            insert psas;
        }

        TestDataFactory.resetFieldNameValuePairs();
        return testUser;
    }

    /*------------------------------------------------------------
    Author:      Sven Kretschmann
    Company:     Salesforce
    Description: Create a new test queue for the given sobjecttype
    Inputs:      Name of the Group and the SObjectType

    Returns:     Group
    ------------------------------------------------------------*/
    public static Group createQueue(String name, String forObjectType) {
        return createQueue(name, new Set<String>{
            forObjectType
        });
    }

    /*------------------------------------------------------------
    Author:      Sven Kretschmann
    Company:     Salesforce
    Description: Create a new test queue for the given sobjecttype
    Inputs:      Name of the Group and the SObjectType

    Returns:     Group
    ------------------------------------------------------------*/
    public static Group createQueue(String name, Set<String> forObjectTypes) {
        Group testQueue = new Group(
            Name = name,
            DeveloperName = name,
            Type = 'Queue'
        );

        System.runAs(getRunningUser()) {
            insert testQueue;

            List<QueueSobject> sobjectAssignments = new List<QueueSobject>();

            for (String type : forObjectTypes) {
                sobjectAssignments.add(
                    new QueueSobject(
                        SobjectType = type,
                        QueueId = testQueue.Id
                    )
                );
            }

            insert sobjectAssignments;
        }

        return testQueue;
    }

    /*------------------------------------------------------------
    Author: Sven Kretschmann
    Company: Salesforce
    Description: Wrapper class for test users to ease setting them up for tests.
                 see https://github.com/flexchecks/TestCustomPermissions for more information
    ------------------------------------------------------------*/
    public class TestUser {
        private final String userName;
        private final Schema.User user;
        private final String profileName;
        private final Id permissionSetId;
        private final Map<String, Id> setupEntityAccessIds;
        private Map<String, Id> customPermissionIds;

        public TestUser() {
            this('Standard User');
        }

        public TestUser(String profileName) {
            this.profileName = profileName;

            this.userName = String.join(
                new String[]{
                    UserInfo.getOrganizationId(),
                    String.valueOf(Datetime.now().getTime()),
                    String.valueOf(Crypto.getRandomInteger())
                },
                '-'
            ).left(68) + '@example.com';

            this.user = new Schema.User(
                Username = this.userName,
                Email = this.userName,
                LastName = 'X' + (this.userName.left(79)).replaceAll('\\W+', '_').replace('_{2,}', '_'),
                Alias = String.valueOf(Crypto.getRandomInteger()).left(8),
                EmailEncodingKey = 'UTF-8',
                LanguageLocaleKey = 'en_US',
                LocaleSidKey = 'en_US',
                TimeZoneSidKey = 'America/New_York',
                IsActive = true,
                ProfileId = [
                    SELECT Id
                    FROM Profile
                    WHERE Name = :THIS.profileName
                    LIMIT 1
                ][0].Id
            );

            PermissionSet permissionSet = new PermissionSet(
                Name = this.user.LastName,
                Label = this.user.Username
            );

            // Insert new Standard User
            System.runAs(TestDataFactory.getRunningUser()) {
                insert user;
            }

            // Insert Permission Set
            System.runAs(TestDataFactory.getRunningUser()) {
                insert permissionSet;

                insert new PermissionSetAssignment(
                    PermissionSetId = permissionSet.Id,
                    AssigneeId = user.Id
                );
            }

            // Assert has no assigned Custom Permissions
            {
                Set<Id> assignedPermissionSetIds = new Set<Id>();
                for (PermissionSetAssignment permissionSetAssignment : [
                    SELECT PermissionSetId
                    FROM PermissionSetAssignment
                    WHERE AssigneeId = :THIS.user.Id
                ]) {
                    assignedPermissionSetIds.add(permissionSetAssignment.PermissionSetId);
                }

                System.assertEquals(
                    true,
                    [
                        SELECT Id, DeveloperName
                        FROM CustomPermission
                        WHERE Id IN (
                            SELECT SetupEntityId
                            FROM SetupEntityAccess
                            WHERE SetupEntityType = 'CustomPermission'
                            AND ParentId IN :assignedPermissionSetIds
                        )
                    ].isEmpty()
                );
            }

            // Set Permission Set Id
            {
                PermissionSetAssignment[] permissionSetAssignments = [
                    SELECT PermissionSetId, PermissionSet.Name
                    FROM PermissionSetAssignment
                    WHERE AssigneeId = :THIS.user.Id
                    AND PermissionSet.ProfileId = NULL
                ];

                System.assertEquals(1, permissionSetAssignments.size());
                System.assertEquals(this.user.LastName, permissionSetAssignments[0].PermissionSet.Name);

                this.permissionSetId = permissionSetAssignments[0].PermissionSetId;
            }

            // Assert User has no assigned Custom Permissions
            System.assertEquals(true, this.getAssignedCustomPermissions().isEmpty());

            // Set Setup Entity Access IDs
            this.setupEntityAccessIds = new Map<String, Id>();
        }

        public Schema.User getUser() {
            return this.user;
        }

        public CustomPermission[] getAssignedCustomPermissions() {
            return [
                SELECT Id, DeveloperName
                FROM CustomPermission
                WHERE Id IN (
                    SELECT SetupEntityId
                    FROM SetupEntityAccess
                    WHERE SetupEntityType = 'CustomPermission'
                    AND ParentId = :THIS.permissionSetId
                )
            ];
        }

        public Id getCustomPermissionId(String developerName) {
            if (this.customPermissionIds == null) {
                this.customPermissionIds = new Map<String, Id>();

                for (CustomPermission customPermission : [
                    SELECT Id, DeveloperName
                    FROM CustomPermission
                    ORDER BY DeveloperName
                ]) {
                    this.customPermissionIds.put(customPermission.DeveloperName, customPermission.Id);
                }
            }

            return this.customPermissionIds.get(developerName);
        }

        private Map<String, Id> getSetupAccessEntityIds() {
            return this.setupEntityAccessIds;
        }

        public TestUser assignCustomPermission(String developerName) {
            if (this.getSetupAccessEntityIds().get(developerName) == null) {
                Id customPermissionId = this.getCustomPermissionId(developerName);
                System.assertNotEquals(null, customPermissionId, 'No CustomPermission found with DeveloperName: ' + developerName);

                SetupEntityAccess setupEntityAccess = new SetupEntityAccess(
                    ParentId = this.permissionSetId,
                    SetupEntityId = customPermissionId
                );

                System.runAs(TestDataFactory.getRunningUser()) {
                    insert setupEntityAccess;
                    this.setupEntityAccessIds.put(developerName, setupEntityAccess.Id);
                }

                System.runAs(this.user) {
                    System.assertEquals(true, FeatureManagement.checkPermission(developerName));
                }
            }
            return this;
        }

        public TestUser unassignCustomPermission(String developerName) {
            Object setupEntityAccessId = this.getSetupAccessEntityIds().remove(developerName);
            if (setupEntityAccessId != null) {
                Database.delete((Id) setupEntityAccessId);
            }
            return this;
        }

        /*------------------------------------------------------------
        Author:      Sven Kretschmann
        Company:     Salesforce
        Description: Assign this user to the named permission set
        Inputs:      Name of the permission set

        Returns:     void
        ------------------------------------------------------------*/
        public TestUser assignPermissionSet(String permissionSetName) {
            return this.assignPermissionSets(new Set<String>{
                permissionSetName
            });
        }

        /*------------------------------------------------------------
        Author:      Sven Kretschmann
        Company:     Salesforce
        Description: Assign the given user to the named permission sets
        Inputs:      User and names of the permission sets

        Returns:     void
        ------------------------------------------------------------*/
        public TestUser assignPermissionSets(Set<String> permissionSetNames) {
            /* first remove already assigned permission sets */
            List<PermissionSetAssignment> existingAssignments = [
                SELECT
                    Id,
                    PermissionSet.Name
                FROM
                    PermissionSetAssignment
                WHERE
                PermissionSet.Name IN :permissionSetNames
                AND
                AssigneeId = :THIS.user.Id
            ];

            for (PermissionSetAssignment psa : existingAssignments) {
                permissionSetNames.remove(psa.PermissionSet.Name);
            }

            List<PermissionSet> permissionSets = [SELECT Id FROM PermissionSet WHERE Name IN :permissionSetNames];

            System.assertEquals(permissionSets.size(), permissionSetNames.size(), 'Not existing permission set name found');

            List<PermissionSetAssignment> newAssignments = new List<PermissionSetAssignment>();

            for (PermissionSet ps : permissionSets) {
                newAssignments.add(new PermissionSetAssignment(
                    AssigneeId = this.user.Id,
                    PermissionSetId = ps.Id
                ));
            }

            System.runAs(TestDataFactory.getRunningUser()) {
                insert newAssignments;
            }

            return this;
        }

        /*------------------------------------------------------------
        Author:      Sven Kretschmann
        Company:     Salesforce
        Description: Make the user a member of the given group
        Inputs:      The group to relate this user to

        Returns:     void
        ------------------------------------------------------------*/
        public TestUser assignToGroup(Group g) {
            System.runAs(TestDataFactory.getRunningUser()) {
                insert new GroupMember(
                    GroupId = g.Id,
                    UserOrGroupId = this.user.Id
                );
            }

            return this;
        }
    }

    public class UnsupportedObjectTypeException extends Exception {
    }
    public class UnavailableRecordTypeException extends Exception {
    }

}