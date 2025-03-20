@isTest
private class KSAPaymentTriggerTest{
	private static testmethod void loadKSAPaymentTriggerTest(){
        Account testAccount = new Account();
        testAccount.Name = 'TestAccount';
        insert testAccount;

		Contact ct = new Contact();
		ct.FirstName = 'FName123';
		ct.LastName = 'LName123';
		ct.Email = 'fff1223@test.com';
        ct.MobilePhone = '121';
        ct.AccountId = testAccount.Id;
        
        insert ct;
         fw1__Payment_center_setting__c setting = new fw1__Payment_center_setting__c();
        setting.Name = 'Default Settings';
        insert setting;
        Quote__c qte = new Quote__c(Paid_Amount__c=100,Contact__c=ct.Id);
        insert qte;
        fw1__Invoice__c invoice = new fw1__Invoice__c();
        //invoice.fw1__Opportunity__c = opp.Id;
        //invoice.fw1__Payment_Plan__c = pyt.Id;
        invoice.Quote__c = qte.Id;
        //insert invoice;
        Set<Id> quoteIds = new Set<Id>();
        quoteIds.add(qte.Id);
        KSAPaymentTriggerHandler.updateQuotePaidAmount(quoteIds);
        Test.startTest();
        system.debug('paye: =='+qte);
        fw1__Payment__c pyt = new fw1__Payment__c(Quote__c=qte.Id,fw1__Status__c='Captured',fw1__Payment_Date__c=System.now());
        insert pyt;
        
        
        // system.debug('after insert: =='+pyt);
       // pyt = [select fw1__Total_Paid_Amount__c from fw1__Payment__c where id =: pyt.Id];
        //System.assertNotEquals(null, pyt);
       
        
        // SETUP RECORD - add processor
        fw1.PackagedData.restoreStripeData();
        
        PaymentCenterSampleCodes.payNow(); 
        
        Test.stopTest();
	}
}