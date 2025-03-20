trigger KSAPaymentTrigger on fw1__Payment__c (after insert,after update) {
    Set<Id> quoteIds = new Set<Id>();
    Set<Id> invoiceIds = new Set<Id>();
    Map<Id,fw1__Payment__c> quotePayments = new Map<Id,fw1__Payment__c>();
    system.debug('paye: ==0000');
    for(fw1__Payment__c payment:Trigger.new)
    {
        system.debug('payment: =='+payment);
        if(payment.Quote__c!=null && payment.fw1__Status__c== 'Captured')
        {
            quoteIds.add(payment.Quote__c);
            quotePayments.put(payment.id,payment);
        }
        if(payment.fw1__Invoice__c!=null && payment.fw1__Status__c== 'Captured')
        {
            invoiceIds.add(payment.fw1__Invoice__c);
        }        
    }
    system.debug('quoteIds: =='+quoteIds);
    if(quoteIds.Size()>0)
    {
        KSAPaymentTriggerHandler.updateQuotePaidAmount(quoteIds);
    }
    
    /*if(invoiceIds.size()>0)
    {
        KSAPaymentTriggerHandler.updateInvoicePaidAmount(invoiceIds);
    }*/
    
}