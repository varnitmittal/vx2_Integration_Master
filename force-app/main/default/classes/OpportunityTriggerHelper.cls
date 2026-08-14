public with sharing class OpportunityTriggerHelper {
  public static void ExecuteAccountOnboarding(List<Opportunity> newOppsList, Map<Id, Opportunity> oldOppsMap){
    List<Opportunity> oppsListForAcctOnboarding = new List<Opportunity>();
    
    for(Opportunity opp: newOppsList){
      if(opp.StageName == 'Closed Won' && oldOppsMap?.get(opp.Id)?.StageName != opp.StageName){
        oppsListForAcctOnboarding.add(opp);
      }
    }
    
    if(!oppsListForAcctOnboarding.isEmpty()){
      QueueAccountOnboarding(oppsListForAcctOnboarding);
    } else {
      System.debug('****** No Valid Opportunity Found for QueueAccountOnboarding  ******');
    }
    
  }
  
  private static void QueueAccountOnboarding(List<Opportunity> oppsListForAcctOnboarding){
    //finding the closed won opportunity that have potential account
    Map<Id, Opportunity> closedWonOppForAcctOnboarding = filterOppForAcctOnboarding(oppsListForAcctOnboarding);
    
    if(!closedWonOppForAcctOnboarding.isEmpty()){
      //found some accounts for onboarding
      //change the recordType of the accounts
      List<Id> convertedAccountIds = convertAccountRT(closedWonOppForAcctOnboarding);
      if (!convertedAccountIds.isEmpty()){
        Id jobId = System.enqueueJob(new OnboardedAccountConvertLeadContacts(convertedAccountIds));
        System.debug('OnboardedAccountConvertLeadContacts enqueueJob Id ====>>>'+ jobId);
      }
    }
  }
  
  //returning account id mapped with valid closing opp record
  private static Map<Id, Opportunity> filterOppForAcctOnboarding(List<Opportunity> oppsListForAcctOnboarding){
    Set<Id> filteredOppIds = new Map<Id, Opportunity>(oppsListForAcctOnboarding).keySet();
    //Filter Opps moved to Closed Won for Prospective Accounts. Account id mapped with valid closing opp record
    Map<Id, Opportunity> closedOppForAcctOnboarding = new Map<Id, Opportunity>();
    //Get Prospective Account Record Type.
    Id prospectiveAccountRtId =  Schema.SObjectType.Account.getRecordTypeInfosByDeveloperName().get('Prospective').getRecordTypeId();
    
    //Find Closed Won Opps with Accounts populated and the acct recordtype is Prospective
    for(Opportunity opp: [SELECT id, Account.recordTypeId FROM Opportunity 
          WHERE id IN :filteredOppIds AND StageName = 'Closed Won' AND Account.recordTypeId = :prospectiveAccountRtId]){
      if(!closedOppForAcctOnboarding.containsKey(opp.AccountId)){ //check if account already there
        closedOppForAcctOnboarding.put(opp.AccountId, opp); //put new opp if not there
      }
    }
    
    return closedOppForAcctOnboarding;
  }
  
  private static List<Id> convertAccountRT(Map<Id, Opportunity> closedWonOppForAcctOnboarding){
    Id customerAccountRtId =  Schema.SObjectType.Account.getRecordTypeInfosByDeveloperName().get('Customer').getRecordTypeId();
    List<Account> accountsToConvert = new List<Account>();
    List<Id> convertedAccountIds = new List<Id>();
    for(Account acc: [SELECT id, recordTypeId, ConversionDate__c FROM Account WHERE id IN :closedWonOppForAcctOnboarding.keySet() FOR UPDATE]){
      acc.recordtypeId = customerAccountRtId;
      acc.ConversionDate__c =  Date.today();
      accountsToConvert.add(acc);
    }
    
    Database.SaveResult[] results = Database.update(accountsToConvert, false);
    
    for(Database.SaveResult dsr : results) {
      if(dsr.isSuccess()) {
        //removing the failed accounts and corresponding list of contacts
        convertedAccountIds.add(dsr.getId());
      } else {
        for (Database.Error err : dsr.getErrors()) {
          System.debug(err.getMessage());
        }
      }
    }
    
    return convertedAccountIds;
  }
}