public with sharing class StripeMockDataController {
  public class CalloutResult {
    @AuraEnabled public Integer statusCode;
    @AuraEnabled public String status;
    @AuraEnabled public String body;
    @AuraEnabled public Map<String, String> headers;
  }
  
  @AuraEnabled
  public static CalloutResult fireMockCallout(Id recordId, Integer statusCode) {
    StripeMockCallout callout = new StripeMockCallout(String.valueOf(statusCode));
    HttpResponse response = callout.fireCallout();
    
    CalloutResult result = new CalloutResult();
    result.statusCode = response.getStatusCode();
    result.status = response.getStatus();
    
    result.body = response.getBody();
    
    result.headers = new Map<String, String>();
    for (String headerName : response.getHeaderKeys()) {
      result.headers.put(headerName, response.getHeader(headerName));
    }
    
    return result;
  }
}