public with sharing class OnboardedAccountConvertContacts implements Queueable {
  private Set<Id> convertedContactIds;
  private List<Id> convertedAccountIds;
  private final Id customerContactRtId = Schema.SObjectType.Contact.getRecordTypeInfosByDeveloperName().get('Customer').getRecordTypeId();
  private final Id potentialContactRtId = Schema.SObjectType.Contact.getRecordTypeInfosByDeveloperName().get('Potential_Customer').getRecordTypeId();
  
  public OnboardedAccountConvertContacts(Set<Id> convertedContactIds, List<Id> convertedAccountIds){
    this.convertedContactIds = convertedContactIds; //leads converted to contact
    this.convertedAccountIds = convertedAccountIds; //accounts
  }
  
  public void execute(QueueableContext qc){
    Map<Id, Contact> contactsToUpdateMap = getContactsToConvert();
    List<Contact> convertedContactsForSharing = convertContacts(contactsToUpdateMap);
    shareConvertedContacts(convertedContactsForSharing);
  }
  
  /**
   * Queries Contacts related to the converted Accounts that either
   * were converted from a Lead or are currently Potential Customers.
   */
  private Map<Id, Contact> getContactsToConvert(){
    return new Map<Id, Contact>([
      SELECT Id, RecordTypeId, ConversionDate__c, Account.BillingCountry
      FROM Contact
      WHERE AccountId IN :convertedAccountIds
      AND (Id IN :convertedContactIds OR RecordTypeId = :potentialContactRtId)
    ]);
  }
  
  /**
   * Updates the given Contacts to the Customer record type with today's
   * conversion date, and returns the ones that were saved successfully.
   */
  private List<Contact> convertContacts(Map<Id, Contact> contactsToUpdateMap){
    List<Contact> convertedContactsForSharing = new List<Contact>();
    
    if(contactsToUpdateMap.isEmpty()){
      return convertedContactsForSharing;
    }
    
    for(Contact c : contactsToUpdateMap.values()){
      c.recordTypeId = customerContactRtId;
      c.ConversionDate__c = Date.today();
    }
    
    Database.SaveResult[] dsrList = Database.update(contactsToUpdateMap.values(), false);
    
    for(Database.SaveResult dsr : dsrList){
      if(dsr.isSuccess()){
        System.debug('OnboardedAccountConvertContacts processed Contact Id   ====>' + dsr.getId());
        convertedContactsForSharing.add(contactsToUpdateMap.get(dsr.getId()));
      } else {
        logErrors('OnboardedAccountConvertContacts FAILED Contact Id   ====>' + dsr.getId(), dsr.getErrors());
      }
    }
    
    return convertedContactsForSharing;
  }
  
  /**
   * Orchestrates sharing the newly converted Contacts with active
   * Standard users in the same country as each Contact's Account.
   */
  private void shareConvertedContacts(List<Contact> convertedContactsForSharing){
    if(convertedContactsForSharing.isEmpty()){
      return;
    }
    
    Map<String, List<Id>> countryMappedUsersList = getUsersByCountry(convertedContactsForSharing);
    List<ContactShare> csList = buildContactShares(convertedContactsForSharing, countryMappedUsersList);
    insertContactShares(csList);
  }
  
  /**
   * Builds a map of BillingCountry -> active Standard User Ids,
   * covering all distinct countries found on the given Contacts' Accounts.
   */
  private Map<String, List<Id>> getUsersByCountry(List<Contact> convertedContactsForSharing){
    Map<String, List<Id>> countryMappedUsersList = new Map<String, List<Id>>();
    
    for(Contact c : convertedContactsForSharing){
      String country = c.Account.BillingCountry;
      if(String.isBlank(country) || countryMappedUsersList.containsKey(country)){
        continue;
      }
      countryMappedUsersList.put(country, new List<Id>());
    }
    
    for(User u : [
      SELECT Id, Country__c
      FROM User
      WHERE isActive = true AND usertype = 'Standard' AND Country__c IN :countryMappedUsersList.keySet()
    ]){
      countryMappedUsersList.get(u.Country__c).add(u.Id);
    }
    
    System.debug('countryMappedUsersList   ' + countryMappedUsersList);
    System.debug('convertedContactsForSharing   ' + convertedContactsForSharing);
    
    return countryMappedUsersList;
  }
  
  /**
   * Constructs a ContactShare (Edit access, Manual row cause) for every
   * Contact/User pairing within the same billing country.
   */
  private List<ContactShare> buildContactShares(List<Contact> convertedContactsForSharing, Map<String, List<Id>> countryMappedUsersList){
    List<ContactShare> csList = new List<ContactShare>();
    
    for(Contact c : convertedContactsForSharing){
      String billingCountryStr = c.Account.BillingCountry;
      if(String.isBlank(billingCountryStr) || countryMappedUsersList.get(billingCountryStr).isEmpty()){
        continue;
      }
      
      for(Id uId : countryMappedUsersList.get(billingCountryStr)){
        ContactShare cs = new ContactShare();
        cs.ContactId = c.Id;
        cs.UserOrGroupId = uId;
        cs.ContactAccessLevel = 'Edit';
        cs.RowCause = Schema.ContactShare.RowCause.Manual;
        csList.add(cs);
      }
    }
    
    System.debug('csList   ' + csList);
    
    return csList;
  }
  
  /**
   * Inserts the given ContactShares, logging any failures per record.
   */
  private void insertContactShares(List<ContactShare> csList){
    if(csList.isEmpty()){
      return;
    }
    
    Database.SaveResult[] dsrListCS = Database.insert(csList, false);
    
    for(Database.SaveResult dsr : dsrListCS){
      if(dsr.isSuccess()){
        System.debug('OnboardedAccountConvertContacts created ContactShare for ContactShareId ====>' + dsr.getId());
      } else {
        logErrors('OnboardedAccountConvertContacts failed ContactShare  ====>', dsr.getErrors());
      }
    }
  }
  
  /**
   * Shared error-logging helper to avoid repeating the same loop everywhere.
   */
  private void logErrors(String prefix, Database.Error[] errors){
    for(Database.Error err : errors){
      System.debug(LoggingLevel.ERROR, prefix + ' || ' + err.getStatusCode() + ' || ' + err.getMessage());
    }
  }
}





























// public with sharing class OnboardedAccountConvertContacts implements Queueable {
  //   private List<Id> convertedContactIds;
  //   private List<Id> convertedAccountIds;
  //   private final Id customerContactRtId = Schema.SObjectType.Contact.getRecordTypeInfosByDeveloperName().get('Customer').getRecordTypeId();
  //   private final Id potentialContactRtId = Schema.SObjectType.Contact.getRecordTypeInfosByDeveloperName().get('Potential_Customer').getRecordTypeId();
  
  //   public OnboardedAccountConvertContacts(List<Id> convertedContactIds, List<Id> convertedAccountIds){
    //     this.convertedContactIds = convertedContactIds; //leads converted to contact
    //     this.convertedAccountIds = convertedAccountIds; //accounts
  //   }
  
  //   public void execute(QueueableContext qc){
    //     List<Contact> convertedContactsForSharing = new List<Contact>();
    //     Map<Id, Contact> contactsToUpdateMap = new Map<Id, Contact>([ SELECT Id, RecordTypeId, 
//       ConversionDate__c, Account.BillingCountry FROM Contact 
//       WHERE AccountId IN :convertedAccountIds AND 
//       (Id IN :convertedContactIds OR RecordTypeId = :potentialContactRtId)]);
    
    //     for(Contact c: contactsToUpdateMap.values()){
      //       c.recordTypeId = customerContactRtId;
      //       c.ConversionDate__c = Date.today();
    //     }
    
    //     if(!contactsToUpdateMap.isEmpty()){
      //       Database.SaveResult[] dsrList = Database.update(contactsToUpdateMap.values(), false);
      
      //       for(Database.SaveResult dsr: dsrList){
        //         if(dsr.isSuccess()){
          //           System.debug('OnboardedAccountConvertContacts processed Contact Id   ====>' + dsr.getid());
          //           convertedContactsForSharing.add(contactsToUpdateMap.get(dsr.getId()));
        //         } else {
          //           for( Database.Error err: dsr.getErrors() ){
            //             System.debug(LoggingLevel.ERROR,
            //             'OnboardedAccountConvertContacts FAILED Contact Id   ====>' +
            //               dsr.getId() + ' || ' + err.getStatusCode() + ' || ' + err.getMessage());
          //           }
        //         }
      //       }
    //     }
    
    //     if(!convertedContactsForSharing.isEmpty()){
      //       //Getting the map of countries and associated users
      //       Map<String, List<Id>> countryMappedUsersList = new Map<String, List<Id>>();
      //       List<ContactShare> csList = new List<ContactShare>();
      
      //       for (Contact c : convertedContactsForSharing) {
        //         String country = c.Account.BillingCountry;
        
        //         if (String.isBlank(country) || countryMappedUsersList.containsKey(country)) {
          //           continue;
        //         }
        
        //         countryMappedUsersList.put(country, new List<Id>());
      //       }
      //       for(User u: [SELECT Id, Country__c FROM User WHERE isActive = true AND usertype = 'Standard' AND 
//            Country__c IN :countryMappedUsersList.keySet()]){
        //         countryMappedUsersList.get(u.Country__c).add(u.Id);
      //       }
      
      //       System.debug('countryMappedUsersList   '+countryMappedUsersList);
      
      //       System.debug( 'convertedContactsForSharing   '+ convertedContactsForSharing);
      
      //       for(Contact c: convertedContactsForSharing){
        //         String BillingCountryStr = c.Account.BillingCountry;
        //         if(!String.isBlank(BillingCountryStr) && !countryMappedUsersList.get(BillingCountryStr).isEmpty()){
          //           for(Id uId: countryMappedUsersList.get(BillingCountryStr)){
            
            //             ContactShare cs =  new ContactShare();
            //             cs.ContactId = c.Id;
            //             cs.UserOrGroupId = uId;
            //             cs.ContactAccessLevel = 'Edit';
            //             cs.RowCause = Schema.ContactShare.RowCause.Manual;
            //             csList.add(cs);
          //           }
        //         }
      //       }
      
      //       System.debug('csList   ' + csList);
      
      //       if(!csList.isEmpty()){
        
        //         Database.SaveResult[] dsrListCS = Database.insert(csList, false);
        //         for(Database.SaveResult dsr: dsrListCS){
          //           if(dsr.isSuccess()){
            //             System.debug('OnboardedAccountConvertContacts created ContactShare for ContactShareId ====>' + dsr.getid());
          //           } else {
            //             for( Database.Error err: dsr.getErrors() ){
              //               System.debug(LoggingLevel.ERROR,
              //               'OnboardedAccountConvertContacts failed ContactShare  ====>' +
              //                 ' || ' + err.getStatusCode() + ' || ' + err.getMessage());
            //             }
          //           }
        //         }
      //       }
    //     }
  //   }
// }