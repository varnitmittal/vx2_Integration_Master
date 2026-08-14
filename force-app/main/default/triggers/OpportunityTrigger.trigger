trigger OpportunityTrigger on Opportunity (after insert, after update) {

  if(Trigger.isAfter){
    if(Trigger.isInsert){
      OpportunityTriggerHandler.afterInsert(Trigger.new);
    }
    if(Trigger.isUpdate){
      OpportunityTriggerHandler.afterUpdate(Trigger.new, Trigger.oldMap);
    }
  }

}