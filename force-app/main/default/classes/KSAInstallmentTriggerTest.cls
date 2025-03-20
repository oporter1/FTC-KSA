@isTest(seeallData=true)
public class KSAInstallmentTriggerTest {
    private static testmethod void UpdateAutoCreatedInstallmentsTest(){
        Account testAccount = new Account();
        testAccount.Name = 'TestAccount';
        insert testAccount;
        
        Contact ct = new Contact();
        ct.FirstName = 'FName123';
        ct.LastName = 'LName123';
        ct.Email = 'fff1223@test.com';
        ct.MobilePhone = '121';
        ct.MailingStreet = 'test.com';
        ct.MailingCity = 'BNG';
        ct.MailingState = 'New';
        ct.MailingPostalCode = '112121';
        ct.AccountId = testAccount.Id;
        
        insert ct;
        system.debug('CT id: '+ct);
        fw1__Payment_Plan__c pyt = new fw1__Payment_Plan__c(fw1__Schedule__c='Daily',fw1__Installment_Fee__c=100);
        insert pyt;
        
        List<fw1__Plan_Installment__c> shcedulePayments = new List< fw1__Plan_Installment__c>();
        fw1__Plan_Installment__c plan1 = new fw1__Plan_Installment__c();
        plan1.fw1__Payment_Plan__c = pyt.Id;
        plan1.fw1__Installment_Number__c = 1;
        plan1.fw1__Installment_Percentage__c = 100;
        insert plan1;
        
        
        Opportunity opp = new Opportunity(Payment_Plan__c=pyt.Id,AccountId=testAccount.Id,Name = 'ETTest',StageName='Value Proposition',OwnerId=UserInfo.getUserId(),CloseDate = Date.newinstance(2022, 2, 17));
        insert opp;
        
        fw1__Invoice__c invoice = [Select Id,Name from fw1__Invoice__c LIMIT 1];
        
        List<fw1__Installment__c> installments = new List<fw1__Installment__c>();
        
        fw1__Installment__c inst = new fw1__Installment__c();
        inst.Name = 'Test';
        inst.fw1__Installment_Date__c = SYstem.today().addDays(10);
        inst.fw1__Installment_Amount__c = 10000;
        inst.fw1__Invoice__c=invoice.id;
        
        installments.add(inst);
        insert installments;
        KSAInstallmentTriggerHandler.updateAutoCreatedInstallments(installments);
    }
}