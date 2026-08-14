public with sharing class ContactTriggerHandler {
  public static void afterUpdate(List<Contact> contactListNew, Map<Id, Contact> contactsOldMap){
    List<Contact> contactListNewFiltered = new List<Contact>();
    for(Contact c: contactListNew){
      if(c.AccountId != null && contactsOldMap.get(c.Id).Made_Primary_Timestamp__c != c.Made_Primary_Timestamp__c){
        System.debug('ContactTimestamps   ' +contactsOldMap.get(c.Id).Made_Primary_Timestamp__c + ' ' + c.Made_Primary_Timestamp__c);
        contactListNewFiltered.add(c);
      }
    }
    if(!contactListNewFiltered.isEmpty()){
      //Firing triggering account again on purpose to try recurion
      ContactTriggerHelper.updateAccountPrimaryContactChangeDate(contactListNewFiltered);
    }
  }
}