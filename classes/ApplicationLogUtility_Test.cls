/*------------------------------------------------------------
Author: Ralf Buttgereit
Company: Sky DE
Description: Test Class for ApplicationLogUtility
Inputs: n.a.
Test Class: n.a.

History
<Date>		<Authors Name> 		<Brief Description of Change>
31.08.2018	Ralf Buttgereit 	Initial creation
------------------------------------------------------------*/
@isTest
private class ApplicationLogUtility_Test {

    private static void assertlogListSize(Integer expectedNumber) {
        System.assertEquals(expectedNumber, ApplicationLogUtility.logList.size(), 'Invalid number of loglist entries');
    }
    
    @isTest static void logOneMessageUsingObject() {
        Test.startTest();
		ApplicationLogUtility.flush();
   		Application_Log__c log = new Application_Log__c(
            Debug_Level__c			= 'Debug',
            Source__c				= 'ApplicationLogUtility_Test',
            Source_Function__c		= 'logOneMessageUsingObject',
            Message__c				= 'Here we are',
            Stack_Trace__c			= null,
            Integration_Payload__c	= 'Here we are',
            Timer__c				= 1
        );
        ApplicationLogUtility.logMessage(log);
        assertlogListSize(1);
        Test.stopTest();
    }
    
    @isTest static void logOneMessageUsingParams() {
        Test.startTest();
		String myStackTrace;
        ApplicationLogUtility.flush();
		// provoke/log an exception
        try {
            Integer i = 1/0;
        } catch (exception e) {
    	    ApplicationLogUtility.logMessage('Debug', 'ApplicationLogUtility_Test', 'logOneMessageUsingParams',
	                                         'Here we are', 'Here we are', e, 1);
            myStackTrace = e.getStackTraceString();
        }
        assertlogListSize(1);
        System.assertEquals(myStackTrace, ApplicationLogUtility.logList[0].Stack_Trace__c, 'Wrong stack trace message');
        Test.stopTest();
    }
    
    @isTest static void logOneMessageSync() {
        Test.startTest();
        ApplicationLogUtility.flush();
        ApplicationLogUtility.logMessageSync('Debug', 'ApplicationLogUtility_Test', 'logOneMessageSync',
                                             'Here we are', 'Here we are', null, 1);
        assertlogListSize(0);
        Test.stopTest();
    }
    
    @isTest static void logMessageListAndAutoFlush() {
        Test.startTest();        
        ApplicationLogUtility.flush();

        // pre-load the list
        Integer maxLoops;
        maxLoops = Limits.getLimitDmlRows()-1;
        for (Integer i=1; i<=maxLoops; i++) {
	   		Application_Log__c logItem = new Application_Log__c(
    	        Debug_Level__c			= 'Debug',
        	    Source__c				= 'ApplicationLogUtility_Test',
            	Source_Function__c		= 'logMessageListAndAutoFlush',
            	Stack_Trace__c			= null,
	            Message__c = 'Here we are for the ' + i + '. time',
            	Integration_Payload__c	= 'Here we are',
            	Timer__c				= 1
        	);
            ApplicationLogUtility.logList.add(logItem);
        }
		// add the one to reach the list capacity        
        ApplicationLogUtility.logMessage('Debug', 'ApplicationLogUtility_Test', 'logMessageListAndAutoFlush',
                                        'Here we are one time too often', 'Here we are', null, 1);   
        // 0 log records expected, because the automatic flush should just have flushed
        assertlogListSize(0);
        Test.stopTest();
    }
    
    @isTest static void logMessagesExceedingLimitDmlStatements() {
        Test.startTest();        
        ApplicationLogUtility.flush();

        // pre-load the list
        Integer maxLoops;
        maxLoops = Limits.getLimitDmlStatements();
        for (Integer i=1; i<=maxLoops; i++) {
            ApplicationLogUtility.logMessageSync('Debug', 'ApplicationLogUtility_Test', 'logMessagesExceedingLimitDmlStatements', 'Here we are for the ' + i + '. time', 'Here we are', null, 1);
        }
		// add the one to exceed the limits
        ApplicationLogUtility.logMessageSync('Debug', 'ApplicationLogUtility_Test', 'logMessagesExceedingLimitDmlStatements',
                                        'Here we are one time too often', 'Here we are', null, 1);
        Test.stopTest();
    }

}