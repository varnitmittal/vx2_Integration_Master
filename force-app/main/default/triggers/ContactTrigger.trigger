trigger ContactTrigger on Contact (after update) {
  if(Trigger.isAfter){
    if(Trigger.isUpdate){
      ContactTriggerHandler.afterUpdate(Trigger.new, Trigger.oldMap);
    }
  }
}