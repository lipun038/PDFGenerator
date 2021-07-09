public without sharing class ActivityReportController {
    public Activity__c activity{get;set;}
    public User techRep{get;set;}
    public List<Contact> attendees{get;set;}
    public Job__c project{get;set;}
    public Account contractor{get;set;}
    public List<Observation__c> obList{get;set;}
    public Map<string,List<string>> obImageMap{get;set;}
    public List<Repair_For_Warranty__c> deList{get;set;}
    public Map<string,List<string>> deImageMap{get;set;}
    public string signatureId{get;set;}
    public ActivityReportController(ApexPages.StandardController stdController) {
        activity = (Activity__c)stdController.getRecord();
        activity = [SELECT Id,Name,Activity_Date__c,Job__c,Tech_Rep__c,Activity_Type__c,twodbm__Roofer__c,twodbm__ReInspection__c,twodbm__Repair_photos_required__c,twodbm__Status__c FROM Activity__c WHERE Id = :activity.Id];
        if(activity.Tech_Rep__c == Null){
            techRep = new User();    
        }else{
            techRep = [SELECT Name,Email,Phone FROM User WHERE Id = :activity.Tech_Rep__c];    
        }
        attendees = new List<Contact>();
        project = new Job__c();
        Id jobContactsId = Schema.SObjectType.Contact.getRecordTypeInfosByName().get('Job Contacts').getRecordTypeId();
        if(activity.Job__c != Null){
            attendees = [SELECT Name,Type__c FROM Contact WHERE  recordtypeId = :jobContactsId AND Type__c='Inspection Contact' AND Job__c = :activity.Job__c];
        	project = [SELECT Name,twodbm__Job_Name__c,twodbm__Address_Line_1__c,twodbm__Address_Line_2__c,twodbm__City__c,twodbm__State__c,twodbm__Country__c,twodbm__Zipcode__c,twodbm__NOC_Receive_Date__c FROM Job__c WHERE Id = :activity.Job__c];
        }
        contractor = new Account();
        if(activity.twodbm__Roofer__c != Null){
        	contractor = [SELECT Name,Phone,twodbm__Cell_Phone__c,twodbm__Email__c,BillingStreet,BillingCity,BillingState,BillingCountry,BillingPostalCode FROM Account WHERE Id = :activity.twodbm__Roofer__c];
        }
        obList = [SELECT Name,twodbm__Comment__c FROM Observation__c WHERE twodbm__Activity__c = :activity.Id];
        obImageMap = new Map<string,List<string>>();
        if(! obList.isEmpty()){
            for(Observation__c ob : obList){
            	 obImageMap.put(ob.id,new List<String>());    
            }
        	for(ContentDocumentLink dl : [SELECT ContentDocumentId,LinkedEntityId FROM ContentDocumentLink WHERE LinkedEntityId IN :obImageMap.keySet() AND ContentDocument.FileType IN ('JPEG','PNG','JPG')]){
                List<String> tempList = obImageMap.get(dl.LinkedEntityId);
                tempList.add(dl.ContentDocumentId);
                obImageMap.put(dl.LinkedEntityId,tempList);
        	}     
        }
        deList = [SELECT Name,twodbm__Comment__c,twodbm__Category__c,twodbm__Defect__c,twodbm__Repair__c FROM Repair_For_Warranty__c WHERE twodbm__Activity__c = :activity.Id];
        deImageMap = new Map<string,List<string>>();
        if(! deList.isEmpty()){
            for(Repair_For_Warranty__c de : deList){
            	 deImageMap.put(de.id,new List<String>());    
            }
        	for(ContentDocumentLink dl : [SELECT ContentDocumentId,LinkedEntityId FROM ContentDocumentLink WHERE LinkedEntityId IN :deImageMap.keySet() AND ContentDocument.FileType IN ('JPEG','PNG','JPG')]){
                List<String> tempList = deImageMap.get(dl.LinkedEntityId);
                tempList.add(dl.ContentDocumentId);
                deImageMap.put(dl.LinkedEntityId,tempList);
        	}     
        }
        List<ContentDocumentLink> slList=[SELECT ContentDocumentId,LinkedEntityId,ContentDocument.Title FROM ContentDocumentLink WHERE LinkedEntityId = :activity.id AND ContentDocument.FileType IN ('JPEG','PNG','JPG') AND ContentDocument.Title = 'Signature'];
        if(! slList.isEmpty()){
        	signatureId = slList[0].ContentDocumentId;    
        }
    }
    @AuraEnabled
    public static string generateReport(string activityId){
        string returnStr = '';
        PageReference pr = new PageReference('/apex/twodbm__ActivityReport');
        pr.getParameters().put('id', activityId);
        Blob data = pr.getContent();
        ContentVersion cv = new ContentVersion(PathOnClient='Activity Report.pdf',Title='Activity Report.pdf',VersionData=data,FirstPublishLocationId=activityId);
        try{
            insert cv;
            returnStr = cv.id;
        }catch(DmlException ex){
            returnStr = ex.getMessage();
        }
        return returnStr;
    }
}
