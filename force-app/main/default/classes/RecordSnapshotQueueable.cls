public with sharing class RecordSnapshotQueueable implements Queueable, Database.AllowsCallouts {
  private string queryStr;
  public RecordSnapshotQueueable(String queryStr, String userid){
    this.queryStr = queryStr;
    System.debug('Initiated by user '+  userId); //queueables run in user mode who initiated it anyhow
  }
  
  public void execute(QueueableContext qc){
    try{
      SObject record = Database.query(queryStr);
      String jsonPayload = JSON.serialize(record);
      MongoERPCallout mec = new MongoERPCallout(jsonPayload);
      mec.handleCalloutLogic();
    } catch(Exception e){
      System.debug(LoggingLevel.ERROR, e.getMessage());
    }
  }
  
}

/*
LWC
  │
  │ Confirm
  ↓
  RecordSnapshotController
  │
  │ validate + create snapshot
  ↓
  RecordSnapshotQueueable
  │
  │ HTTP callout
  ↓
  ERP
  │
  ├── 2xx ───────────────→ SUCCESS
  │
  ├── 4xx ───────────────→ FAILED
  │
  ├── 429 ──┐
  │         │
  ├── 5xx ──┤
  │         │
  └─ timeout┘
  ↓
  RETRY QUEUEABLE
  ↓
  exponential backoff
   */