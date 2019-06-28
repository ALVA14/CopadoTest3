/*------------------------------------------------------------
Author: Ralf Buttgereit
Company: Sky DE
Description: Test Class for ApplicationLogUtilityPurge
Inputs: n.a.
Test Class: n.a.

History
<Date>		<Authors Name> 		<Brief Description of Change>
03.09.2018	Ralf Buttgereit 	Initial creation
------------------------------------------------------------*/
@isTest
private class ApplicationLogUtilityPurge_Test {
    private static final Decimal nD = Decimal.valueOf(ApplicationLogUtilityPurge.NUMDAY.Value__c);
	
    @testSetup
    static void doPrepare() {
        list<Application_Log__c> logList = Test.loadData(Application_Log__c.sObjectType, 'BulkTestLogData');
        System.debug(logList.size() + ' records uploaded');
    }
    
    @isTest 
    static void doPurge() {
        Test.startTest();
        ApplicationLogUtilityPurge aLUP = new ApplicationLogUtilityPurge();
        list<Application_Log__c> logList = [select id from Application_Log__c where Age__c > :nD];
        System.debug('> ' + nD + ' days old: ' + logList.size());
        logList = [select id from Application_Log__c where Age__c <= :nD];
        Integer recordsToKeep = logList.size();
        System.debug('<= ' + nD + ' days old: ' + logList.size());
        ID batchprocessid = Database.executeBatch(aLUP);
		// stopTest is here because Database.executebatch is async. and stopTest is forcing it to be done.
        Test.stopTest();
        logList = [select id from Application_Log__c];
        System.assertEquals(recordsToKeep, logList.size(), 'Invalid number of loglist entries');
    }
    
}