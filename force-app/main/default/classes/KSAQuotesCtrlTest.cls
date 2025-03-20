@isTest
public class KSAQuotesCtrlTest {
    /*@isTest static void loadKSAQuotesCtrlTest() {
        Account testAccount = new Account();
        testAccount.Name = 'TestAccount';
        insert testAccount;
        
        List<Contact> lstContact = new List<Contact>();
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
        lstContact.add(ct);
        
        Contact ct1 = new Contact();
        ct1.FirstName = 'FName123';
        ct1.LastName = 'LName123';
        ct1.Email = 'fff1223@test.com';
        ct1.MobilePhone = '121';
        ct1.MailingStreet = 'test.com';
        ct1.MailingCity = 'BNG';
        ct1.MailingState = 'New';
        ct1.MailingPostalCode = '112121';
        ct1.AccountId = testAccount.Id;
        lstContact.add(ct1);
        insert lstContact;

        fw1__Payment_Plan__c pyt = new fw1__Payment_Plan__c(fw1__Schedule__c='Daily',fw1__Installment_Fee__c=100);
        insert pyt;
        
        List<fw1__Plan_Installment__c> shcedulePayments = new List< fw1__Plan_Installment__c>();
        fw1__Plan_Installment__c plan1 = new fw1__Plan_Installment__c();
        plan1.fw1__Payment_Plan__c = pyt.Id;
        plan1.fw1__Installment_Number__c = 1;
        plan1.fw1__Installment_Percentage__c = 100;
        insert plan1;

        Opportunity opId = new Opportunity(Payment_Plan__c=pyt.Id,AccountId=testAccount.Id,Name = 'ETTest',StageName='Value Proposition',OwnerId=UserInfo.getUserId(),CloseDate = Date.newinstance(2022, 2, 17));
        insert opId;
        opId = [select Id,KSA_Webcode__c from Opportunity where Id=:opId.Id];
        System.assertNotEquals(null, opId.KSA_Webcode__c);
        
        Opportunity opId1 = new Opportunity(Payment_Plan__c=pyt.Id,AccountId=testAccount.Id,Name = 'ETTest12',StageName='Closed Lost',OwnerId=UserInfo.getUserId(),CloseDate = Date.newinstance(2022, 2, 17));
        insert opId1;
        
        opId1 = [select id,KSA_Webcode__c from Opportunity where id=:opId.Id];
        System.assertNotEquals(null, opId1.KSA_Webcode__c);

        Quote__c qte = new Quote__c(Contact__c=ct.Id,Card_Type__c='American Express',Credit_Card_Number__c='370000000000002',CVV__c='000',
                                    Exp_Date__c='',Opportunity__c=opId.Id,Paid_Amount__c=1999.0);
        insert qte;
        Quote__c qte1 = new Quote__c(Contact__c=ct1.Id,Card_Type__c='American Express',Credit_Card_Number__c='370000000000002',CVV__c='000',
                                     Exp_Date__c='',Opportunity__c=opId1.Id,Paid_Amount__c=1999.0, Quote_By__c = 'COACH', is_Head_Coach__c = true);
        insert qte1;
        
        //String athRec = Schema.getGlobalDescribe().get('Registrations__c').getDescribe().getRecordTypeInfosByName().get('Athlete').getRecordTypeId();
        List<Registrations__c> lstRegistrations = new List<Registrations__c>();
        Registrations__c reg = new Registrations__c();
        reg.Opportunity__c = opId1.Id;
        reg.First_Name__c = 'Test';
        reg.Last_Name__c = 'Test Last Name';
        //reg.RecordTypeId = athRec;
        reg.Quote__c = qte1.Id;
        insert reg;

        
 		Test.startTest();
        Set<String> setWebCodeIds = new Set<String>();
        setWebCodeIds.add(opId.KSA_Webcode__c);
       	KSAQuotesCtrl.getQuotes(String.valueOf(ct1.Id));
        Map<String, List<Quote__c>> mapQuote = KSAQuotesCtrl.getQuotesForCoach(setWebCodeIds, String.valueOf(ct1.Id));
        List<fw1__Invoice__c> lstInvoice = KSAQuotesCtrl.getInvoices(String.valueOf(ct1.Id));
        List<fw1__Invoice__c> lstManualInvoice = KSAQuotesCtrl.getManualInvoices(String.valueOf(ct1.Id));
        KSAQuotesCtrl.getCoachEventInfo(String.valueOf(ct1.Id));
        KSAQuotesCtrl.getRoomingListInfo(String.valueOf(opId1));
        KSAQuotesCtrl.codeCoverage();
        //KSAQuotesCtrl.getInvoiceLine(String.valueOf(lstInvoice.get(0).Id));
        //KSAQuotesCtrl.getPaymentInfo(String.valueOf(lstManualInvoice.get(0).Id));
        Test.stopTest();
    }*/
}