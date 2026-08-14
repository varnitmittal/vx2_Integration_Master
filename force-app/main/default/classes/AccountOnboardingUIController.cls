public with sharing class AccountOnboardingUIController {
  
  @AuraEnabled(cacheable=true)
  public static AccountRelatedRecords getRelatedRecords(Id accountId) {
    AccountRelatedRecords result = new AccountRelatedRecords();
    
    result.contacts = [SELECT Id, Name FROM Contact WHERE AccountId = :accountId ORDER BY Name LIMIT 5];
    
    result.leads = [SELECT Id, Name FROM Lead WHERE Account__c = :accountId ORDER BY Name LIMIT 5];
    
    return result;
  }
  
  public class AccountRelatedRecords {
    
    @AuraEnabled
    public List<Contact> contacts;
    
    @AuraEnabled
    public List<Lead> leads;
    
    public AccountRelatedRecords() {
      contacts = new List<Contact>();
      leads = new List<Lead>();
    }
  }
}