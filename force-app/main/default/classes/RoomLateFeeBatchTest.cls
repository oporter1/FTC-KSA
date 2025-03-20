@isTest
public with sharing class RoomLateFeeBatchTest {
    public static testMethod void roomLateFeeBatchSchedTest(){
        fw1__Payment_Center_Setting__c settings = new fw1__Payment_Center_Setting__c();
        settings.Name = 'Default Settings';
        settings.fw1__Flat_Fee_Amount__c = 100;
        settings.fw1__Number_of_Days_Late__c = 5;
        settings.Apply_Room_Late_Fee__c = true;
        settings.Minimum_Balance_Due_for_Late_Fee__c = 100;
        insert settings;
        
        List<fw1__Payment_Center_Setting__c> pcSettingsList = [SELECT Id, Name FROM fw1__Payment_Center_Setting__c];
        
        fw1__Payment_Center_Setting__c settingstest1 = fw1.ControlHelper.getSettings();

        //create Account
        Account testAcct = new Account();
        testAcct.Name = 'Test Account 1';
        testAcct.BillingCountry = 'US';
        testAcct.BillingStreet = '123 Main St';
        testAcct.BillingCity = 'Chicago';
        testAcct.BillingState = 'IL';
        testAcct.BillingPostalCode = '60603';
        insert testAcct;
            
        //create contact
        Contact newContact = new Contact();
        newContact.AccountId = testAcct.Id;
        newContact.FirstName = 'John';
        newContact.LastName = 'Smith';
        newContact.Email = 'testcontact001@ksatest001.com';
        insert newContact;
        
        //create invoice
        fw1__Invoice__c inv = new fw1__Invoice__c();
        inv.fw1__Account__c = testAcct.Id;
        inv.fw1__Terms__c = 30;
        inv.fw1__Due_Date__c = Date.today().addDays(-5);
        insert inv;
        
        //create product
        Product2 testProduct = new Product2();
        testProduct.Name = 'Test Product 1';
        testProduct.IsActive = true;
        testProduct.Family = 'Room Rates';
        testProduct.Sales_Price__c = 1000;
        insert testProduct;
        
        //create invoice line
        fw1__Invoice_Line__c testInvLine1 = new fw1__Invoice_Line__c();
        testInvLine1.Name = 'BBB CL Double Room';
        testInvLine1.fw1__Quantity__c = 1;
        testInvLine1.fw1__Unit_Price__c = 1200;
        testInvLine1.fw1__Invoice__c = inv.Id;
        testInvLine1.fw1__Product2__c = testProduct.Id;
        insert testInvLine1;
        
        String jobId;
        Test.startTest();
        Datetime dt = Datetime.now() + (0.020833); // after 30 mins
        string cron = dt.format('s m H d M \'?\' yyyy');
        
        jobId = System.schedule('LateFeeNoticeBatchSchedulerTest',cron,new RoomLateFeeBatch());
        RoomLateFeeBatch invoiceJob = new RoomLateFeeBatch();
        Database.executebatch(invoiceJob,50);
        
		Test.stopTest();
        List<fw1__Additional_Charge__c> additionalChargeList = [SELECT Id, fw1__Fixed_Amount__c, fw1__Invoice__c FROM fw1__Additional_Charge__c];
        
        Boolean isAdditionalChargeCreated = false;
        if(!additionalChargeList.isEmpty()){
            fw1__Additional_Charge__c theCharge = additionalChargeList[0];
            if(theCharge.fw1__Fixed_Amount__c == 100){
                isAdditionalChargeCreated = true;
            }
        }
        System.assertEquals(true, isAdditionalChargeCreated);
    }
}