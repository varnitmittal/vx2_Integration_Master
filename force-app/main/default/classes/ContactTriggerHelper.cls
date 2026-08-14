public with sharing class ContactTriggerHelper {
  public static void updateAccountPrimaryContactChangeDate(List<Contact> contactListNewFiltered){
    Set<Id> accountIdsToUpdate = new Set<Id>();
    for(contact c: contactListNewFiltered){
      accountIdsToUpdate.add(c.AccountId);
    }
    if(!accountIdsToUpdate.isEmpty()){
      List<Account> accountsToUpdateList = new List<Account>();
      for(Account acc: [SELECT Id, Primary_Contact_Timestamp__c FROM Account WHERE Id IN :accountIdsToUpdate FOR UPDATE]){
        acc.Primary_Contact_Timestamp__c = acc.Primary_Contact_Timestamp__c != null ? acc.Primary_Contact_Timestamp__c.addHours(2) : Datetime.now().addHours(2);
        accountsToUpdateList.add(acc);
      }
      if(!accountsToUpdateList.isEmpty()){
        update accountsToUpdateList;
        // Database.Saveresult[] dsrList = Database.update(accountsToUpdateList, false);
        // for(Database.SaveResult dsr: dsrList){
          //   if(!dsr.isSuccess()){
            //     dmlErrorLogging('DML:accountsToUpdateList', dsr.getErrors());
          //   }
        // }
      }
    }
  }
  
  // private static void dmlErrorLogging(String prefix, List<Database.Error> dsrErrors){
    //   for(Database.Error err : dsrErrors){
      //     System.debug(LoggingLevel.ERROR,'Class:ContactTriggerHelper  ' + prefix +
      //       ' |||||==========>>>>>' +  err.getStatusCode() + '  ||||  ' + err.getMessage());
    //   }
  // }
}