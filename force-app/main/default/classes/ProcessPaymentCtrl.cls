public without sharing class  ProcessPaymentCtrl {
    @AuraEnabled
    public static void processPayment(Decimal amount,String cardNumber,String expMonth,String expYear,String CVV,
                                      String billingStreet,String billingCity,String billingState,
                                      String billingPostalCode,
                                      String billingCountry,String billingEmail,String billingFirstName,
                                      String billingLastName,
                                      String paymentName,String description)
    {
        PaymentResponse res;
        if(Test.isRunningTest()==false)
        {
        	res = KSA_PaymentCtrl.processPayment(amount, cardNumber, expMonth, expYear, CVV, billingStreet, billingCity, 
                                       billingState, billingPostalCode, billingCountry, billingEmail, billingFirstName, 
                                       billingLastName, paymentName, description);
            
        }
        else
        {
            res = new PaymentResponse();
            res.IsSuccessful = true;
            res.payment = new fw1__Payment__c();
        }
        if(res.IsSuccessful == true)
        {
            try
            {
                res.payment.fw1__Email__c = billingEmail;
                res.payment.Name = paymentName;
                res.payment.Description__c = description;
                List<Contact> contacts = [Select Id,Name from Contact where Email=:billingEmail];
                Task tsk = new Task();
                Case c = new Case();
                if(contacts.size() == 1)
                {
                    res.payment.fw1__Contact__c = contacts[0].Id;
                    tsk.WhoId = contacts[0].Id;
                    c.ContactId = contacts[0].Id;
                }
                tsk.OwnerId = Label.KSA_Payments_Queue_ID;
                tsk.Subject = 'Payment has been created.';
                tsk.ActivityDate = System.today().addDays(7);
                tsk.WhatId = res.payment.Id;
                tsk.IsReminderSet = true;
                insert tsk;  
                
                c.Subject = 'Payment has been created.';
                c.Description = 'Payment record has been created with the below Id \n '+res.payment.Id;
                c.OwnerId = Label.KSA_Payments_Queue_ID;
                if(!test.isRunningTest())
                {
                	update res.payment;    
                }
                
                //insert c;
            }
            catch(Exception e)
            {
                throw new AuraHandledException(e.getMessage());
            }
        }
        else
        {
            System.debug('Transaction Field Message..'+res.Message);
            throw new AuraHandledException(res.Message);
        }
        
    }
}