public with sharing class OnboardedAccountConvertLeadContacts implements Queueable {
  private List<id> convertedAccountIds;
  private static final Integer batchLimiting = 95; //row limit-- 100 LeadConvert per Database.convertLead()
  
  public OnboardedAccountConvertLeadContacts(){}
  
  public OnboardedAccountConvertLeadContacts(List<Id> convertedAccountIds){
    this.convertedAccountIds = convertedAccountIds;
  }
  
  public void execute(QueueableContext qc){
    String convertedStatus = [SELECT MasterLabel FROM LeadStatus WHERE IsConverted = true LIMIT 1].MasterLabel;
    //Findging out count of leads to decide normal flow or batching (as limit on no. of batch jobs in flex queue)
    Integer leadCount = [SELECT COUNT() FROM Lead WHERE IsConverted = false AND Email != null AND Account__c IN :convertedAccountIds];
    
    if (leadCount > 0) {
      if(leadCount > batchLimiting){
        //we go batch!
        Database.executeBatch(new BatchConvertLeadContacts(convertedAccountIds, convertedStatus), batchLimiting);
      } else{
        //we stay here
        Set<Id> convertedContactIds = leadConversionLogic([SELECT Id, Account__c FROM Lead WHERE isConverted = false 
        AND Email != '' AND Account__c IN :convertedAccountIds], convertedStatus);
        Id jobId = System.enqueueJob(new OnboardedAccountConvertContacts(convertedContactIds, this.convertedAccountIds));
        System.debug('OnboardedAccountConvertContacts enqueueJob Id ====>>>'+ jobId);
      }
    } else {
      //no lead found!
      Id jobId = System.enqueueJob(new OnboardedAccountConvertContacts(new Set<Id>(), convertedAccountIds));
      System.debug('OnboardedAccountConvertContacts enqueueJob Id ====>>>'+ jobId);
    }
  }
  
  public Set<Id> leadConversionLogic(List<Lead> leadList,String convertedStatus){
    List<Database.LeadConvert> conversionsList = new List<Database.LeadConvert>();
    Set<Id> convertedContactIds = new Set<Id>();
    
    for(Lead l : leadList){
      Database.LeadConvert conversion = new Database.LeadConvert();
      conversion.setLeadId(l.Id);
      conversion.setAccountId(l.Account__c);
      conversion.setConvertedStatus(convertedStatus);
      conversion.setDoNotCreateOpportunity(true);
      conversionsList.add(conversion);
    }
    
    if(!conversionsList.isEmpty()){
      List<Database.LeadConvertResult> results = Database.convertLead(conversionsList, false);
      
      for (Database.LeadConvertResult result : results) {
        if (result.isSuccess() && result.getContactId() != null) {
          convertedContactIds.add(result.getContactId());
        }else {
          for (Database.Error error : result.getErrors()) {
            System.debug(LoggingLevel.ERROR, 'Lead conversion failed: ' + error.getStatusCode() + ' - ' + error.getMessage());
          }
        }
      }
    }
    return convertedContactIds;
  }
}