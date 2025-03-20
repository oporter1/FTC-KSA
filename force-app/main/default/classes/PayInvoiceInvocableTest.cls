@isTest
public class PayInvoiceInvocableTest {

    @isTest
    static void testPayNow_SuccessfulPayment() {
                  // SETUP RECORD - add Payment Center Settings
        fw1__Payment_center_setting__c setting = new fw1__Payment_center_setting__c();
        setting.Name = 'Default Settings';
        insert setting;
        
            
        // Create an Account
        Account testAccount = new Account(Name = 'Account Test');
        insert testAccount;

        // Create an Opportunity related to the above created Account
        Opportunity testOpportunity = new Opportunity(
            Name = 'Opp Test',
            AccountId = testAccount.Id,
            CloseDate = Date.newInstance(2024, 1, 1),
            StageName = 'Inquiry'
        );
        insert testOpportunity;
        
          //create contact
        Contact newContact = new Contact();
        newContact.AccountId = testAccount.Id;
        newContact.FirstName = 'John';
        newContact.LastName = 'Smith';
        newContact.fw1__Billing_Contact__c = true;
        newContact.Email = 'testcontact001@ksatest001.com';
        insert newContact;
        
        //create invoice
        fw1__Invoice__c inv = new fw1__Invoice__c();
        inv.fw1__Account__c = testAccount.Id;
        inv.fw1__Terms__c = 30;
        inv.fw1__Due_Date__c = Date.today().addDays(10);
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

        // Now set the Opportunity and Invoice IDs, as well as the payment processor in the testInput object
        PayInvoiceInvocable.PaymentInput testInput = new PayInvoiceInvocable.PaymentInput();
        testInput.Name = 'Test Invoice';
        testInput.Amount = 100.00;
        testInput.CreditCardType = 'Visa';
        testInput.FirstName = 'John';
        testInput.LastName = 'Smith';
        testInput.CreditCardNumber = '4111111111111111';
        testInput.ExpiryMonth = '12';
        testInput.ExpiryYear = '26';
        testInput.BillingStreet = '123 Main St';
        testInput.BillingCity = 'Anytown';
        testInput.BillingState = 'CA';
        testInput.BillingZip = '12345';
        testInput.Email = 'test@example.com';
        testInput.oppId = testOpportunity.Id;
        testInput.invoiceId = inv.Id;
        testInput.autoPay = true;
        testInput.creditCardFee = 5;
        testInput.creditCardLabel = 'Credit Card Fee';
        testInput.surchargeIsServiceFee = false;
       

        // Test PayNow method
        Test.startTest();
        List<PayInvoiceInvocable.ProcessorResponseOutput> results = PayInvoiceInvocable.payNow(new List<PayInvoiceInvocable.PaymentInput>{testInput});
        Test.stopTest();

        // Assertions
        System.assertNotEquals(0, results.size());
        PayInvoiceInvocable.ProcessorResponseOutput result = results[0];
       
        
    }

    @isTest
    static void testPayNow_FailedPayment() {
        
                  // SETUP RECORD - add Payment Center Settings
        fw1__Payment_center_setting__c setting = new fw1__Payment_center_setting__c();
        setting.Name = 'Default Settings';
        insert setting;
       
           
            
        // Create an Account
        Account testAccount = new Account(Name = 'Account Test');
        insert testAccount;

        // Create an Opportunity related to the above created Account
        Opportunity testOpportunity = new Opportunity(
            Name = 'Opp Test',
            AccountId = testAccount.Id,
            CloseDate = Date.newInstance(2024, 1, 1),
            StageName = 'Inquiry'
        );
        insert testOpportunity;
        
          //create contact
        Contact newContact = new Contact();
        newContact.AccountId = testAccount.Id;
        newContact.FirstName = 'John';
        newContact.LastName = 'Smith';
        newContact.fw1__Billing_Contact__c = true;
        newContact.Email = 'testcontact001@ksatest001.com';
        insert newContact;
        
        //create invoice
        fw1__Invoice__c inv = new fw1__Invoice__c();
        inv.fw1__Account__c = testAccount.Id;
        inv.fw1__Terms__c = 30;
        inv.fw1__Due_Date__c = Date.today().addDays(10);
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

        // Now set the Opportunity and Invoice IDs, as well as the payment processor in the testInput object
        PayInvoiceInvocable.PaymentInput testInput = new PayInvoiceInvocable.PaymentInput();
        testInput.Name = 'Test Invoice';
        testInput.Amount = 100.00;
        testInput.CreditCardType = 'Visa';
        testInput.FirstName = 'John';
        testInput.LastName = 'Smith';
        testInput.CreditCardNumber = '4111111111111111';
        testInput.ExpiryMonth = '12';
        testInput.ExpiryYear = '21';
        testInput.BillingStreet = '123 Main St';
        testInput.BillingCity = 'Anytown';
        testInput.BillingState = 'CA';
        testInput.BillingZip = '12345';
        testInput.Email = 'test@example.com';
        testInput.oppId = testOpportunity.Id;
        testInput.invoiceId = inv.Id;
        testInput.autoPay = true;
        testInput.creditCardFee = 5;
        testInput.creditCardLabel = 'Credit Card Fee';
        testInput.surchargeIsServiceFee = false;

     

        // Test PayNow method
        Test.startTest();
        List<PayInvoiceInvocable.ProcessorResponseOutput> results = PayInvoiceInvocable.payNow(new List<PayInvoiceInvocable.PaymentInput>{testInput});
        Test.stopTest();

        // Assertions for exception handling
        System.assertNotEquals(0, results.size());
        PayInvoiceInvocable.ProcessorResponseOutput result = results[0];
        System.assertNotEquals(null, result.ErrorMessage);
    }
}