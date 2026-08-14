public with sharing class OpportunityTriggerHandler {
  public static void afterInsert(List<Opportunity> newOppsList){
    System.debug('****** Begin OpportunityTriggerHandler afterInsert  ******');
    /*
      Identify eligible Closed Won Opps, convert Accounts to Customer,
      then enqueue onboarding processing for their leads and Contacts.
    */
    OpportunityTriggerHelper.ExecuteAccountOnboarding(newOppsList, null);
    System.debug('****** End OpportunityTriggerHandler afterInsert  ******');
  }

  public static void afterUpdate(List<Opportunity> newOppsList, Map<Id, Opportunity> oldOppsMap){
    System.debug('****** Begin OpportunityTriggerHandler afterUpdate  ******');
    /*
      Identify eligible Closed Won Opps, convert Accounts to Customer,
      then enqueue onboarding processing for their leads and Contacts.
    */
    OpportunityTriggerHelper.ExecuteAccountOnboarding(newOppsList, oldOppsMap);
    System.debug('****** End OpportunityTriggerHandler afterUpdate  ******');
  }
}