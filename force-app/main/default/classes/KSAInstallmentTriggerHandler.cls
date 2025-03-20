public class KSAInstallmentTriggerHandler {
    public static void updateAutoCreatedInstallments(List<fw1__Installment__c> installments)
    {
        Set<Id> invoiceIds = new Set<Id>();
        Set<Id> oppIds = new Set<Id>();
        Map<Id,fw1__Invoice__c> invoicesMap = new Map<Id,fw1__Invoice__c>();
        for(fw1__Installment__c inst:installments)
        {
            if(inst.fw1__Invoice__c!=null)
            {
                invoiceIds.add(inst.fw1__Invoice__c); 
                
            }
        }
        if(invoiceIds.size()>0)
        {
            List<fw1__Invoice__c> invoices = [Select Id,Quote__c,fw1__Opportunity__c
                                              From fw1__Invoice__c Where ID IN:invoiceIds];
            for(fw1__Invoice__c inv:invoices)
            {
                invoicesMap.put(inv.Id,inv);
            }
            for(fw1__Installment__c inst:installments)
            {
                if(inst.fw1__Invoice__c!=null)
                {
                    if( invoicesMap.get(inst.fw1__Invoice__c).Quote__c!=null)
                    {
                        inst.Quote__c = invoicesMap.get(inst.fw1__Invoice__c).Quote__c;     
                    }
                    if( invoicesMap.get(inst.fw1__Invoice__c).fw1__Opportunity__c!=null)
                    {
                        inst.Opportunity__c = invoicesMap.get(inst.fw1__Invoice__c).fw1__Opportunity__c;   
                        oppIds.add(inst.Opportunity__c);
                    }
                    
                }
            }
        }
        if(oppIds.size()>0)
        {
            Set<Id> paymentPlanIds = new Set<Id>();
            Map<String,fw1__Plan_Installment__c> orderPlanInstallment = new Map<String,fw1__Plan_Installment__c>();
            List<Opportunity> opps = [Select Id,Name,Payment_Plan__c FROM 
                                      Opportunity where Id IN :oppIds];
            
            for(Opportunity opp:opps)
            {
                if(opp.Payment_Plan__c!=null)
                {
                    paymentPlanIds.add(opp.Payment_Plan__c);    
                }
            }
            if(paymentPlanIds.size()>0)
            {
                List<fw1__Plan_Installment__c> oppInstallmentPlans = [Select Id,Name,fw1__Installment_Date__c,fw1__Installment_Number__c,
                                                                      fw1__Installment_Percentage__c,fw1__Terms__c,
                                                                      fw1__Use_Current_Date_As_Installment_Date__c
                                                                      FROM fw1__Plan_Installment__c
                                                                      Where fw1__Payment_Plan__c IN : paymentPlanIds];
                for(fw1__Plan_Installment__c planInst:oppInstallmentPlans)
                {
                    if(planInst.Name!=null)
                    {
                        orderPlanInstallment.put(String.valueOf(planInst.Name), planInst);
                    }
                }
                
            }
            if(orderPlanInstallment.size()>0)
            {
                for(fw1__Installment__c inst:installments)
                {
                    if(inst.Name!=null)
                    {
                        if(orderPlanInstallment.get(inst.Name)!=null)
                        {
                            inst.Plan_Installment__c = orderPlanInstallment.get(inst.Name).Id;
                        }
                    }
                }
            }
        }   
    }
}