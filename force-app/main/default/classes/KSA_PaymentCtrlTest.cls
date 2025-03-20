@isTest
public class KSA_PaymentCtrlTest {
   /* @isTest static void loadKSA_PaymentCtrlTest() {
        //fw1__Payment_Processor__c x = new fw1__Payment_Processor__c(Name = 'PayPal Payments Pro');
        //insert x; 
        
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
        Quote__c qte1 = new Quote__c(Contact__c=ct.Id,Card_Type__c='American Express',Credit_Card_Number__c='370000000000002',CVV__c='000',
                                   Exp_Date__c='',Opportunity__c=opId1.Id,Paid_Amount__c=1999.0);
        insert qte1;
        system.debug('qte id: '+qte);
        
        RecordType rt = [SELECT Id FROM RecordType WHERE sObjectType = 'Registrations__c' AND Name = 'ATHLETE'];
        
        Registrations__c regt = new Registrations__c(Quote__c=qte.Id,School_Name__c='Sch name',Webcode__c='100',
                               Sport__c='Baseball',First_Name__c='Fname',Last_Name__c='Lname',Middle_Name__c='Mname',Gender__c='Male',
                               Birth_Date__c=Date.newinstance(2010, 2, 17),Mobile__c='1212',Email__c='email@test.com',
                               Shirt_Size_25__c='Small - $25.00',Relationship_to_Athlete__c='Self',Room_No__c=1,
                               Contact__c=ct.Id,recordtypeid=rt.Id);
        insert regt;
        Test.startTest();
        //KSA_PaymentCtrl.processPayment(String.valueOf(regt.Id));
        //KSA_PaymentCtrl.getRecordDetails(String.valueOf(regt.Id));
        KSA_PaymentCtrl.processPayment(100, '2121121212', 'March', '2022', '000', 'shg', 'sds', 're', 'we', 'wew', '', 'billingFirstName', 'billingLastName', 'paymentName', null);
        //KSA_PaymentCtrl.processQuotePayment(String.valueOf(qte.Id));
        
        Test.stopTest();
        
    }*/
}