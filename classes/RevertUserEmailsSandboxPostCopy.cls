/*------------------------------------------------------------
Author: Jakub Sterba
Company: Salesforce
Description: This class can be executed during Sandbox refresh to fix users' email address
Inputs: "None"
History
21.06.2018 Jakub Sterba PoC
------------------------------------------------------------*/
global class RevertUserEmailsSandboxPostCopy implements SandboxPostCopy {

    global void runApexClass( SandboxContext context ) {

        System.debug( 'Organization ID: ' + context.organizationId() );
        System.debug( 'Sandbox ID: ' + context.sandboxId() );
        System.debug( 'Sandbox Name: ' + context.sandboxName() );

        Database.executeBatch( new RevertUserEmailsBatchable() );

    }

}