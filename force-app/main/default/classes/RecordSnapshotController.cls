public with sharing class RecordSnapshotController {
  
  private static final Id currentUserId = UserInfo.getUserId();
  
  public class LWCInputs{
    @auraEnabled public String recordId {get; set;}
    @auraEnabled public String objectApiName {get; set;}
  }
  
  @auraEnabled
  public static void RecordSnapshotProcessor(LWCInputs input) {
    System.debug('Record Id: ' + input.recordId);
    System.debug('Object API Name: ' + input.objectApiName);
    System.debug('Current UserId: ' + currentUserId);
    
    if(input.objectApiName == null || input.RecordId == null){
      throw new AuraHandledException('Value(s) may be null.');
    } else if(validateInputAccess(input)){
      //need dynamic soql
      String query = createDynamicSoql(input);
      System.debug(query);
      Id jobId = System.enqueueJob(new RecordSnapshotQueueable(query, currentUserId));
      System.debug('RecordSnapshotController enqueued RecordSnapshotQueueable jobId = ' + jobId);
    } else{
      return;
    }
  }
  
  private static Boolean validateInputAccess(LWCInputs input){
    Boolean flag = false;
    //Checking user's access to the object
    Schema.DescribeSObjectResult describeResult = Schema.getGlobalDescribe().get(input.objectApiName).getDescribe();
    if (!describeResult.isAccessible()) {
      throw new AuraHandledException('You do not have access to this object.');
    }
    
    //Checking user's access to the record
    UserRecordAccess recordAccess = [SELECT RecordId, HasReadAccess FROM UserRecordAccess 
      WHERE UserId = :currentUserId AND RecordId = :input.recordId LIMIT 1];
    
    if (!recordAccess.HasReadAccess) {
      throw new AuraHandledException('You do not have access to this record.');
    }
    
    return !flag;
  }
  
  private static String createDynamicSoql(LWCInputs input){
    Map<String, Schema.SObjectField> fields = Schema.getGlobalDescribe().get(input.objectApiName).getDescribe().fields.getMap();
    
    List<String> readableFields = new List<String>();
    
    for (Schema.SObjectField field : fields.values()) {
      if (field.getDescribe().isAccessible()) {
        readableFields.add(field.getDescribe().getName());
      }
    }
    
    String query = 'SELECT ' + String.join(readableFields, ', ') + ' FROM ' +
      String.escapeSingleQuotes(input.objectApiName) + ' WHERE Id = \'' + String.escapeSingleQuotes(input.recordId) + '\'';
    
    return query;
  }
}