/*------------------------------------------------------------
    Author: Stefano Pramparo
    Company: Sky DE
    Description: A utility class for logging functionality, use the flush to store log on DB
    Inputs: n.a.
    Test Class: ApplicationLogUtility_Test
    
    History
    <Date>		<Authors Name> 		<Brief Description of Change>
    31.08.2018	Stefano Pramoaro 	Initial creation
------------------------------------------------------------*/
public class ApplicationLogUtility { 
        private static final Integer DMLHEAP =100;
        @TestVisible 
        private static List<Application_Log__c> logList;
        
        static{
            logList = new List<Application_Log__c>();
        }
        
        /*------------------------------------------------------------ 
    Author: Stefano Pramparo 
    Company: Sky DE
    Description: Function to log error message and flush immediatly
    Inputs: - logLevel: mandatory, values are Error,Warning, Info, Debug
    - sourceClass: object, class, flow, etc. generating error
    - sourceFunction: function name
    - logMessage: message to log
    - payLoad: payload for integration
    - ex: exception
    - timeTaken: execution time 
    Returns: n.a.
    History 
    <Date>	 		<Authors Name>		<Brief Description of Change> 
    31.08.2018		Stefano Pramparo	Created
    ------------------------------------------------------------*/
        public static void logMessageSync(String logLevel,String sourceClass, String sourceFunction,
                                          String logMessage,String payLoad,Exception ex,Long timeTaken){
                                              logMessage(logLevel,sourceClass, sourceFunction,logMessage, payLoad, ex, timeTaken);
                                              flush();
                                          }
        /*------------------------------------------------------------ 
    Author: Stefano Pramparo 
    Company: Sky DE
    Description: Function to add the error message in the lit; data is committed invoking flush method
    or when getLimitDmlRows()-1 has been reached
    Inputs: - logLevel: mandatory, values are Error,Warning, Info, Debug
    - sourceClass: object, class, flow, etc. generating error
    - sourceFunction: function name
    - logMessage: message to log
    - payLoad: payload for integration
    - ex: exception
    - timeTaken: execution time 
    Returns: n.a.
    History 
    <Date>	 		<Authors Name>		<Brief Description of Change> 
    31.08.2018		Stefano Pramparo	Created
    ------------------------------------------------------------*/
        public static void logMessage(String logLevel,String sourceClass, String sourceFunction,
                                      String logMessage,String payLoad,Exception ex,Long timeTaken){
                                          Application_Log__c log = new Application_Log__c(
                                              Debug_Level__c=logLevel,
                                              Source__c=sourceClass,
                                              Source_Function__c=sourceFunction,
                                              Message__c=logMessage,            		
                                              Integration_Payload__c=payLoad,
                                              Timer__c=timeTaken
                                          );
                                          if(ex != null)        
                                              log.Stack_Trace__c=ex.getStackTraceString();
                                          logMessage(log);
                                      }    
        /*------------------------------------------------------------ 
    Author: Stefano Pramparo 
    Company: Sky DE
    Description: Function to add the error message in the lit; data is committed invoking flush method
    or when getLimitDmlRows()-1 has been reached
    Inputs: log: object of type Application_Log__c
    Returns: n.a.
    History 
    <Date>	 		<Authors Name>		<Brief Description of Change> 
    31.08.2018		Stefano Pramparo	Created
    ------------------------------------------------------------*/
        public static void logMessage(Application_Log__c log){
            logList.add(log);
            if(logList.size()==Limits.getLimitDmlRows() || Limits.getHeapSize()+DMLHEAP >= Limits.getLimitHeapSize())
                flush();
        }
        /*------------------------------------------------------------ 
    Author: Stefano Pramparo 
    Company: Sky DE
    Description: Function to flush log array, it will trigger an insert
    Inputs: n.a
    Returns: n.a.
    History 
    <Date>	 		<Authors Name>		<Brief Description of Change> 
    31.08.2018		Stefano Pramparo	Created
    ------------------------------------------------------------*/
        public static void flush(){       
            if(Limits.getDMLStatements()<Limits.getLimitDmlStatements()){
                insert logList;
            }else{
                System.debug('Warning Limits exceed, log records discarded');
            }
            logList.clear();
        }
    }