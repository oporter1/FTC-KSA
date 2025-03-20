public class KSAPaymentTriggerHandler {
    public static void updateQuotePaidAmount(Set<Id> quoteIds)
    {
        List<fw1__Payment__c> quotePayments = [Select Id,Quote__c,fw1__Total_Paid_Amount__c,fw1__Status__c  
                                               from fw1__Payment__c where Quote__c IN:quoteIds];
        List<Quote__c> ksaQuotes = [Select Id,Paid_Amount__c from Quote__c where ID IN: quoteIds];
        
        List<fw1__Invoice__c> invoices = [Select Id,fw1__Total_Paid_Amount__c,Quote__c from fw1__Invoice__c
                                          where Quote__c IN:quoteIds];
        Map<Id,fw1__Invoice__c> quoteInvoices = new Map<Id,fw1__Invoice__c>();
        for(fw1__Invoice__c invoice:invoices)
        {
			quoteInvoices.put(invoice.Quote__c,invoice);  
        }
        
        for(Quote__c quote:ksaQuotes)
        {
            Decimal quotePaidAmount = 0;
            for(fw1__Payment__c payment:quotePayments)
            {
                if(payment.Quote__c!=null && payment.fw1__Status__c== 'Captured')
                {
                    if(quote.Id == payment.Quote__c)
                    {
                        quotePaidAmount = quotePaidAmount + payment.fw1__Total_Paid_Amount__c;
                    }
                }
            }
            quote.Paid_Amount__c = quotePaidAmount;
            if(quoteInvoices.get(quote.Id)!=null)
            {
                quoteInvoices.get(quote.Id).fw1__Total_Paid_Amount__c = quotePaidAmount; 
            }
            
        }
        update ksaQuotes;
        
        update quoteInvoices.values();
    }
    /*public static void updateInvoicePaidAmount(Set<Id> invoiceIds)
    {
        
        List<fw1__Payment__c> invoicePayments = [Select Id,Quote__c,fw1__Total_Paid_Amount__c,fw1__Status__c,fw1__Invoice__c  
                                                 from fw1__Payment__c where fw1__Invoice__c IN:invoiceIds];
        List<fw1__Invoice__c> invoices = [Select Id,fw1__Total_Paid_Amount__c from fw1__Invoice__c
                                          where ID IN: invoiceIds];
        
        for(fw1__Payment__c payment:invoicePayments)
        {
            system.debug('payment: =='+payment);
            if(payment.fw1__Invoice__c!=null && payment.fw1__Status__c== 'Captured')
            {
                invoiceIds.add(payment.fw1__Invoice__c);
            }
        }
        
        Decimal invoicePaidAmount = 0;
        for(fw1__Invoice__c invoice:invoices)
        {
            for(fw1__Payment__c payment:invoicePayments)
            {
                if(payment.fw1__Invoice__c!=null && payment.fw1__Status__c== 'Captured')
                {
                    if(invoice.Id == payment.fw1__Invoice__c)
                    {
                        invoice.fw1__Total_Paid_Amount__c = invoice.fw1__Total_Paid_Amount__c + payment.fw1__Total_Paid_Amount__c;
                    }
                }
            } 
            //invoice.fw1__Total_Paid_Amount__c = invoicePaidAmount;
        }
        System.debug(invoices);
        if(invoices.size()>0)
        {
            update invoices;
        }
        
    }
    
    public static void setInstallmentPaidAmount(Map<Id,fw1__Payment__c> oldMap,Map<Id,fw1__Payment__c> newMap)
    {
        Set<Id> invoiceIds = new Set<Id>();
        for(fw1__Payment__c payment:newMap.values())
        {
            if(payment.fw1__Invoice__c!=null && payment.fw1__Status__c== 'Captured')
            {
                invoiceIds.add(payment.fw1__Invoice__c);
            }   
        }
        List<fw1__Installment__c> invoiceInstallments = [Select Id,Name,fw1__Invoice__c 
                                                         FROM fw1__Installment__c
                                                         WHERE fw1__Invoice__c IN :invoiceIds];
        
        
    }*/
}