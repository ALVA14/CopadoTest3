/*------------------------------------------------------------
Author:      Sudipta Karmakar
Company:     Salesforce
Description: Queueable class for sending live text messages
Inputs:
Test Class:  QueueMessageClass_Test

History
7/2/18    Sudipta Karmakar   Initial Version
------------------------------------------------------------*/

public class QueueMessageClass implements Queueable {
    List<LiveText__SMS_Message__c> RecordsToInsert;
    public QueueMessageClass(List<LiveText__SMS_Message__c> recordsToInsert) {
        this.recordsToInsert = recordsToInsert;
    }
    public void execute(QueueableContext context) {
        insert recordsToInsert;
    }

}