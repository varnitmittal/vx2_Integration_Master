public class IntegrationRetryQueueable implements Queueable, Database.AllowsCallouts {
  private String integrationLogId;
  
  public IntegrationRetryQueueable(String integrationLogId) {
    this.integrationLogId = integrationLogId;
  }
  
  public void execute(QueueableContext context) {
    Integration_Log__c il = [
      SELECT Id, Integration_Service__c
      FROM Integration_Log__c
      WHERE Id = :integrationLogId
      LIMIT 1
    ];
    
    IntegrationCalloutHandler handler;
    
    if (il.Integration_Service__c == 'MongoERP') {
      handler = new MongoERPCallout(/* payload needed to rebuild request */);
    } else {
      throw new IntegrationCalloutHandler.IntegrationException(
        'No retry handler for service: ' + il.Integration_Service__c
        );
    }
    
    handler.setExistingIntegrationLogId(integrationLogId);
    handler.handleCalloutLogic();
  }
}