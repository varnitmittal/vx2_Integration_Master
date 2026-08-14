public with sharing class AccountTriggerHandler {
  
  public static Set<Id> processedAccountIds = new Set<Id>();
  
  public static void beforeInsert(List<Account> newAccountsList){
    //AccountTriggerHelper.customAccountValidations(newAccountsList, null);
  }
  
  public static void beforeUpdate(List<Account> newAccountsList, Map<Id, Account> oldAccountsMap){
    //AccountTriggerHelper.customAccountValidations(newAccountsList, oldAccountsMap);
  }
  
  public static void afterUpdate(List<Account> newAccountsList, Map<Id, Account> oldAccountsMap){
    Map<Account, Id> newAccountsListFilteredMappedPC = new Map<Account, Id>();
    for(Account acc : newAccountsList){
      if(processedAccountIds.contains(acc.Id)){ //added on purpose to block recursion
        continue;
      }
      if(
        (acc.Primary_Contact__c != null && acc.Primary_Contact__c != oldAccountsMap.get(acc.Id).Primary_Contact__c)
        || (acc.Primary_Contact_Timestamp__c != oldAccountsMap.get(acc.Id).Primary_Contact_Timestamp__c)
      ){
        System.debug('AccountTimestamps   ' +oldAccountsMap.get(acc.Id).Primary_Contact_Timestamp__c + ' ' + acc.Primary_Contact_Timestamp__c);
        newAccountsListFilteredMappedPC.put(acc, acc.Primary_Contact__c);
      }
    }
    if(!newAccountsListFilteredMappedPC.isEmpty()){
      AccountTriggerHelper.updateMadePrimaryDateOnContact(newAccountsListFilteredMappedPC);
    }
  }
}