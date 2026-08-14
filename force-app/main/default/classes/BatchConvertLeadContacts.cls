public with sharing class BatchConvertLeadContacts implements Database.Batchable<sObject> {
  private List<id> convertedAccountIds;
  private String convertedStatus;
  
  Set<Id> convertedContactIds = new Set<Id>();
  
  public BatchConvertLeadContacts(List<Id> convertedAccountIds, String convertedStatus) {
    this.convertedAccountIds = convertedAccountIds;
    this.convertedStatus = convertedStatus;
  }
  
  public Database.QueryLocator start(Database.BatchableContext bc){
    return Database.getQueryLocator(
      'SELECT Id, Account__c FROM Lead WHERE isConverted = false AND Email != null AND Account__c IN :convertedAccountIds');
  }
  
  public void execute(Database.BatchableContext bc, List<sObject> scope){
    OnboardedAccountConvertLeadContacts oaclc = new OnboardedAccountConvertLeadContacts();
    this.convertedContactIds.addAll(oaclc.leadConversionLogic((List<Lead>)scope,this.convertedStatus));
  }
  
  public void finish(Database.BatchableContext bc){
    Id jobId = System.enqueueJob(new OnboardedAccountConvertContacts(this.convertedContactIds, this.convertedAccountIds));
    System.debug('BatchConvertLeadContacts enqueued OnboardedAccountConvertContacts JobId ====>>>'+ jobId);
  }
  
}