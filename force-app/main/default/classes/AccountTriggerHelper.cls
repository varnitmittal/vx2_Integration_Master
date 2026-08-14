public with sharing class AccountTriggerHelper {
  public static void updateMadePrimaryDateOnContact(Map<Account, Id> newAccountsListFilteredMappedPC){
    List<Contact> contactsToUpdate = new List<Contact>();
    for(Contact c: [SELECT Id, Made_Primary_Timestamp__c FROM Contact WHERE Id IN :newAccountsListFilteredMappedPC.values() FOR UPDATE]){
      c.Made_Primary_Timestamp__c = c.Made_Primary_Timestamp__c != null ? c.Made_Primary_Timestamp__c.addHours(2) : Datetime.now().addHours(2);
      contactsToUpdate.add(c);
    }
    if(!contactsToUpdate.isEmpty()){
      //added on purpose to block recursion
      for(account a: newAccountsListFilteredMappedPC.keySet()){
        AccountTriggerHandler.processedAccountIds.add(a.Id);
      }
      update contactsToUpdate;
      
      //   Database.Saveresult[] dsrList = Database.update(contactsToUpdate, false);
      //   for(Database.Saveresult dsr : dsrList){
        //     if(!dsr.isSuccess()){
          //       dmlErrorLogging('DML:contactsToUpdate', dsr.getErrors());
        //     }
      //   }
    }
  }
  
  // private static void dmlErrorLogging(String prefix, List<Database.Error> dsrErrors){
    //   for(Database.Error err : dsrErrors){
      //     System.debug(LoggingLevel.ERROR,'Class:AccountTriggerHelper  ' + prefix +
      //       ' |||||==========>>>>>' +  err.getStatusCode() + '  ||||  ' + err.getMessage());
    //   }
  // }
}