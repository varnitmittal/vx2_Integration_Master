public with sharing class MongoERPCallout  extends IntegrationCalloutHandler{
  private String jsonPayload;
  public MongoERPCallout(String jsonPayload) {
    this.jsonPayload = jsonPayload;
  }
  
  //Overriding abstract
  public override String getSourceName(){
    return 'MongoERPCallout';
  }
  public override String getIntegrationService(){
    return 'MongoERP';
  }
  public override String getIntegrationCategory(){
    return 'HTTP_Outbound';
  }
  public override HttpRequest calloutRequestImplementation(){
    HttpRequest req = new HttpRequest();
    req.setEndpoint('callout:mongoconnectAPI2');
    req.setMethod('POST');
    req.setHeader('Content-Type', 'application/json');
    req.setBody(jsonPayload);
    
    System.debug('MongoERPCallout Request Info: ');
    System.debug('=== MONGO CALLOUT ===');
    System.debug('Endpoint: ' + req.getEndpoint());
    System.debug('Method: ' + req.getMethod());
    System.debug('Body: ' + req.getBody());
    
    return req;
  }
}





// public with sharing class MongoERPCallout {
  //   private String jsonPayload;
  //   public MongoERPCallout(String jsonPayload) {
    //     this.jsonPayload = jsonPayload;
  //   }
  
  
  //   //POST
  //   public void fireCallout(){
    //     HttpRequest req = new HttpRequest();
    //     req.setEndpoint('callout:mongoconnectAPI2');
    //     req.setMethod('POST');
    //     req.setHeader('Content-Type', 'application/json');
    //     req.setBody(jsonPayload);
    
    //     System.debug('MongoERPCallout Request Info: ');
    //     System.debug('=== MONGO CALLOUT ===');
    //     System.debug('Endpoint: ' + req.getEndpoint());
    //     System.debug('Method: ' + req.getMethod());
    //     System.debug('Body: ' + req.getBody());
    
    //     Http h = new Http();
    //     HttpResponse res = h.send(req);
    
    //     System.debug('MongoERPCallout Status: ' + res.getStatusCode());
    //     System.debug('MongoERPCallout Status: ' + res.getStatusCode());
    //     System.debug('MongoERPCallout Body: ' + res.getBody());
  //   }
// }