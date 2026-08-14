public abstract with sharing class IntegrationCalloutHandler implements Schedulable {
  //Transaction Control
  private String existingIntegrationLogId;
  
  //custom exception class
  public class IntegrationException extends Exception {}
  
  //configurations from extending class
  protected abstract String getSourceName();
  protected abstract String getIntegrationService();
  protected abstract String getIntegrationCategory();
  protected abstract HttpRequest calloutRequestImplementation();
  
  //Additional configs -- private
  private Integration_Config__mdt inconfig;
  private String IntegrationService; // copy of getIntegrationService  value for less overhead
  private String IntegrationCategory; // copy of getIntegrationCategory value for less overhead
  private Boolean Retry_Enabled;
  private Integer Max_Attempts_Allowed;
  
  public void execute(SchedulableContext sc) {
    handleCalloutLogic();
  }
  
  public void handleCalloutLogic() {
    validateAndPopulateConfigs();
    
    HttpRequest req = calloutRequestImplementation();
    
    try {
      HttpResponse response = fireCallout(req);
      
      // DML is now allowed because the callout already happened
      if (String.isBlank(existingIntegrationLogId)) {
        insertIntegrationLogRecord();
      }
      
      Integer currentAttempt = insertIntegrationAttempt(req, response, false, null);
      updateIntegrationLog(response, false, null);
      processResponseAndRetry(response, currentAttempt);
      
    } catch (Exception ex) {
      if (String.isBlank(existingIntegrationLogId)) {
        insertIntegrationLogRecord();
      }
      
      insertIntegrationAttempt(req, null, true, ex.getMessage());
      updateIntegrationLog(null, true, ex.getMessage());
      
      throw ex;
    }
  }
  
  private HttpResponse fireCallout(HttpRequest req){
    try {
      HttpResponse response = new Http().send(req);
      return response;
    } catch (Exception ex) {
      System.debug(LoggingLevel.ERROR, 'Callout exception: ' + ex.getMessage());
      System.debug(LoggingLevel.ERROR, ex.getStackTraceString());
      throw ex;
    }
  }
  
  private void scheduleRetry(Integer retryAfterSeconds) {
    Datetime retryTime = Datetime.now().addSeconds(retryAfterSeconds);
    
    String cron = retryTime.second() + ' ' +
      retryTime.minute() + ' ' +
      retryTime.hour() + ' ' +
      retryTime.day() + ' ' +
      retryTime.month() + ' ? ' +
      retryTime.year();
    
    System.schedule('Integration Retry - ' + existingIntegrationLogId + ' - ' + Datetime.now().getTime(), cron, this);
  }
  
  private void insertIntegrationLogRecord(){
    Integration_Log__c il = new Integration_Log__c();
    il.Integration_Service__c = IntegrationService;
    il.Integration_Category__c = IntegrationCategory;
    il.Retry_Enabled__c = Retry_Enabled;
    il.Max_Attempts_Allowed__c = Max_Attempts_Allowed;
    il.Error_Message__c = '';
    il.Initiated_By__c = UserInfo.getUserId() + ':::' + getSourceName();
    try {
      insert il;
      existingIntegrationLogId = il.Id;
    } catch (Exception ex) {
      System.debug(LoggingLevel.ERROR, 'Integration error: ' + ex.getMessage());
      System.debug(LoggingLevel.ERROR, ex.getStackTraceString());
      throw ex;
    }
  }
  
  //validating and populating configurations
  private void validateAndPopulateConfigs() {
    if (String.isBlank(getSourceName())) {//check if source name is null
      throw new IntegrationException('Source Name (Class, Trigger, Flow, etc.) is required.');
    }
    
    IntegrationService = getIntegrationService();
    if (String.isBlank(IntegrationService)) { //check if service null
      throw new IntegrationException('Integration service is required.');
    } else{
      inconfig = Integration_Config__mdt.getInstance(IntegrationService);
    }
    
    if(inconfig == null){
      throw new IntegrationException('No such service available.');
    } else if (!inconfig.isActive__c){
      throw new IntegrationException('Service has been disabled.');
    }
    
    Set<String> supportedCategories;
    IntegrationCategory = getIntegrationCategory();
    if (String.isBlank(IntegrationCategory)) {
      throw new IntegrationException('Integration Category is required.');
    } else {
      supportedCategories = new Set<String>((inconfig.Supported_Categories__c).split(';'));
    }
    
    if(supportedCategories == null || !supportedCategories.contains(IntegrationCategory)){
      throw new IntegrationException('Service does not support this integration category');
    }
    
    //populating additional configs
    Retry_Enabled = inconfig.Retry_Enabled__c;
    if(inconfig.Max_Attempts_Allowed__c != null ){
      Max_Attempts_Allowed = inconfig.Max_Attempts_Allowed__c?.intValue();
    }
  }
  
  private void processResponseAndRetry(HttpResponse res, Integer currentAttempt) {
    Integer statusCode = res.getStatusCode();
    
    if (statusCode >= 200 && statusCode < 300) {
      return;
    }
    
    Boolean retryable = statusCode == 429 || statusCode == 502 ||
      statusCode == 503 || statusCode == 504 || statusCode == 429;
    
    if (retryable && Retry_Enabled && currentAttempt < Max_Attempts_Allowed) {
      scheduleRetry(60);
    }
  }
  
  private Integer insertIntegrationAttempt(HttpRequest req, HttpResponse res, Boolean failedHTTP, String exceptionMsg) {
    Integration_Log__c il = [SELECT Id, (SELECT Id, Attempt_Number__c FROM IntegrationAttempts__r ORDER BY CreatedDate DESC LIMIT 1) FROM Integration_Log__c WHERE Id = :existingIntegrationLogId LIMIT 1];
    
    Integration_Attempt__c inat = new Integration_Attempt__c();
    inat.Integration_Log__c = existingIntegrationLogId;
    inat.Attempt_Number__c = il.IntegrationAttempts__r.isEmpty() ? 1 :
      (il.IntegrationAttempts__r[0].Attempt_Number__c).intValue() + 1;
    inat.Error_Message__c = failedHTTP ? exceptionMsg : null;
    inat.HTTP_Endpoint__c = req.getEndpoint();
    inat.HTTP_Status__c = failedHTTP ? 'No HTTP Connection' :
      (res.getStatusCode() >= 200 && res.getStatusCode() < 300 ? 'Success' : 'Failed');
    inat.HTTP_Status_Code__c = failedHTTP ? null : res.getStatusCode();
    inat.Attempt_Timestamp__c = Datetime.now();
    
    if (!failedHTTP && res.getStatusCode() >= 200 && res.getStatusCode() < 300) {
      inat.Will_Retry__c = false;
    } else if (inat.Attempt_Number__c < Max_Attempts_Allowed) {
      inat.Will_Retry__c = true;
      inat.Retry_after_seconds__c = 60;
    } else {
      inat.Will_Retry__c = false;
    }
    
    try {
      insert inat;
      return inat.Attempt_Number__c.intValue();
    } catch (Exception ex) {
      System.debug(LoggingLevel.ERROR, 'insertIntegrationAttempt error: ' + ex.getMessage());
      System.debug(LoggingLevel.ERROR, ex.getStackTraceString());
      throw ex;
    }
  }
  
  private void updateIntegrationLog(HttpResponse res, Boolean failedHTTP, String exceptionMsg) {
    Integration_Log__c il = new Integration_Log__c(Id = existingIntegrationLogId);
    
    if (failedHTTP) {
      il.Error_Message__c = exceptionMsg;
      il.Next_Retry_At__c = null;
    } else if (res.getStatusCode() >= 200 && res.getStatusCode() < 300) {
      il.Error_Message__c = null;
      il.Next_Retry_At__c = null;
    } else {
      il.Error_Message__c = res.getBody();
    }
    
    try {
      update il;
    } catch (Exception ex) {
      System.debug(LoggingLevel.ERROR, 'updateIntegrationLog error: ' + ex.getMessage());
      System.debug(LoggingLevel.ERROR, ex.getStackTraceString());
      throw ex;
    }
  }
}