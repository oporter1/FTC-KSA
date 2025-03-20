trigger KSAInstallmentTrigger on fw1__Installment__c (before insert) {
    if(trigger.isbefore && trigger.isInsert)
    {
    	KSAInstallmentTriggerHandler.UpdateAutoCreatedInstallments(Trigger.new);    
    }
}