/*------------------------------------------------------------
Author: Jakub Sterba
Company: Salesforce
Description: This class reverts all System Administrator users' email addresses by removing the @example.com
Inputs: "None"
History
21.06.2018 Jakub Sterba PoC
------------------------------------------------------------*/ 
 
public with sharing class RevertUserEmailsBatchable implements Database.Batchable<SObject> {

    public Database.QueryLocator start( Database.BatchableContext context ) {
        return Database.getQueryLocator( 'SELECT id, email FROM User WHERE isActive = true and Profile.Name = \'System Administrator\'' );
    }

    public void execute( Database.BatchableContext context, List<User> users ) {

        for ( User u : users ) {

            System.debug( 'user sandbox email: ' + u.email );

            u.email = u.email.replace('@example.com', '').replace('=', '@');

            System.debug( 'user reverted email: ' + u.email );

        }

        update users;

    }

    public void finish( Database.BatchableContext context ) {

    }

}