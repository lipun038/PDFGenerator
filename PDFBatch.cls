public class OpportunityPrinter implements Database.Batchable<SObject>, Database.AllowsCallouts {
    
    public Database.QueryLocator start(Database.BatchableContext context) {
        return Database.getQueryLocator([SELECT Id, Name FROM Opportunity LIMIT 10]);
    }
    
    public void execute(Database.BatchableContext context, List<Opportunity> scopes) {
        Opportunity opportunity = scopes[0];
        
        //use the relative url of your page
        PageReference pr = new PageReference('/apex/GeneratePDF');
        pr.getParameters().put('id', opportunity.Id);
        Blob data = pr.getContent();
        
        //save the PDF as an attachment on the record
        insert new Attachment(
            Name = 'detail.pdf',
            Body = data,
            ParentId = opportunity.Id
        );
    }
    
    public void finish(Database.BatchableContext context) {
        //
    }
}
