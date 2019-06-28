/*------------------------------------------------------------------------
Author: Jakub Sterba
Company: Salesforce
Description: A test class to cover RevertUserEmailsSandboxPostCopy
Tests executed: test_post_copy()

History
21.06.2018 Jakub Sterba PoC
----------------------------------------------------------------------------*/

@isTest
private class RevertUserEmailsSandboxPostCopyTest {

    @isTest
    static void test_post_copy() {

        Profile p = [ SELECT id FROM Profile WHERE name = 'System Administrator' ];

        User user1;

        System.runAs( new User( id = UserInfo.getUserId() ) ) {

            user1 = newUser( p.id, 'Alpha', 'User 1', 'user_1=salesforce.com@example.com' );

            insert user1;

        }

        Test.startTest();

        Test.testSandboxPostCopyScript(
            new RevertUserEmailsSandboxPostCopy(), // apex class to run
            '00D1a000040BlpQ', // org id
            '00D90000000KY45', // sandbox id
            'My Sandbox' // sandbox name
        );

        Test.stopTest();

        user1 = [ SELECT id, email FROM User WHERE id = :user1.id ];

        System.assertEquals( 'user_1@salesforce.com', user1.email );

    }

    private static User newUser( ID profileId, String firstName, String lastName, String email ) {
        Integer rand = Math.round( Math.random() * 1000 );
        return new User(
            isActive = true,
            profileId = profileId,
            alias = firstName.substring(0,1) + lastName.substring(1,5),
            firstName = firstName,
            lastName = lastName,
            email = email,
            username = rand + email,
            emailEncodingKey = 'UTF-8',
            languageLocaleKey = 'en_US',
            localeSidKey = 'en_US',
            timeZoneSidKey = 'America/Chicago'
        );
    }

}