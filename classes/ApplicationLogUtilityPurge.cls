/*------------------------------------------------------------
Author: Stefano Pramparo
Company: Sky DE
Description: A utility class for purging Application_Log__c objects which has Age__c>NUMDAY
Number of days are stored in Application_Log_Configuration__mdt with Label NUMDAY
Inputs: n.a.
Test Class: ApplicationLogUtilityPurge_Test

History
<Date>		<Authors Name> 		<Brief Description of Change>
31.08.2018	Stefano Pramoaro 	Initial creation
------------------------------------------------------------*/
global class ApplicationLogUtilityPurge implements Database.Batchable<sObject>{    
	
    @TestVisible 
    private static final Application_Log_Configuration__mdt NUMDAY=[select Value__c from Application_Log_Configuration__mdt where Label='NUMDAY'];
    
    private static final String Query='select id from Application_Log__c where Age__c > '+NUMDAY.Value__c +' LIMIT '+Limits.getLimitQueryLocatorRows();
    
    global Database.QueryLocator start(Database.BatchableContext BC){
        return Database.getQueryLocator(query);
    }
    
    global void execute(Database.BatchableContext BC, List<sObject> scope){
        delete scope;
    }
    
    global void finish(Database.BatchableContext BC){
    }
    
}