public class CaseTransferController {

    private final Case currentCase;
    public List<Group> availableQueues { get; set; }

    public CaseTransferController(ApexPages.StandardController stdController) {
        this.currentCase = (Case)stdController.getRecord();
        this.availableQueues = [SELECT Id, Name FROM Group WHERE Type = 'Queue'];
    }
    
    public PageReference transfer(){
        return null;
    }

}