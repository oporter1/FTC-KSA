public without sharing class KSA_PaymentCtrl {
   /* @AuraEnabled
    public static PaymentResponse processPayment(String recordId)
    {
        Registrations__c reg = [Select Id,Name,First_Name__c,Last_Name__c,Email__c,Amount__c,
                                Mobile__c,Street__c,City__c,State_Providence__c,Postal_Code__c,
                                Credit_Card_Number__c,Exp_Date__c,
                                CVV__c
                                FROM Registrations__c 
                                WHERE Id=:recordId LIMIT 1];
        PaymentCenterSampleCodes.amount = reg.Amount__c;
        PaymentCenterSampleCodes.billingCity = reg.City__c;
        PaymentCenterSampleCodes.billingCountry = 'US';
        PaymentCenterSampleCodes.billingEmail = reg.Email__c;
        PaymentCenterSampleCodes.billingPostalCode = reg.Postal_Code__c;
        PaymentCenterSampleCodes.billingState = reg.State_Providence__c;
        PaymentCenterSampleCodes.billingStreet = reg.Street__c;
        PaymentCenterSampleCodes.cardNumber = reg.Credit_Card_Number__c;
        PaymentCenterSampleCodes.expMonth = '12';
        PaymentCenterSampleCodes.expYear = '2021';
        PaymentCenterSampleCodes.firstName = reg.First_Name__c;
        PaymentCenterSampleCodes.lastName = reg.Last_Name__c;
        PaymentCenterSampleCodes.paymentName = reg.Name;
        return PaymentCenterSampleCodes.payNow();
    }
    
    //@future(callout=true)
    public static void processQuotePayment(Id quoteId)
    {
        Quote__c quote = [Select Id,Name,Contact__r.FirstName,Contact__r.LastName,Contact__r.Email,
                                Contact__r.MailingStreet,Contact__r.MailingState,Contact__r.MailingCity,
                                Contact__r.MailingPostalCode,
                                Card_Type__c,Credit_Card_Number__c,Exp_Date__c,
                                CVV__c,Paid_Amount__c
                                FROM Quote__c 
                                WHERE Id=:quoteId LIMIT 1];
        
        PaymentCenterSampleCodes.amount = quote.Paid_Amount__c;
        PaymentCenterSampleCodes.billingCity = quote.Contact__r.MailingCity;
        PaymentCenterSampleCodes.billingCountry = 'US';
        PaymentCenterSampleCodes.billingEmail = quote.Contact__r.Email;
        PaymentCenterSampleCodes.billingPostalCode = quote.Contact__r.MailingPostalCode;
        PaymentCenterSampleCodes.billingState = quote.Contact__r.MailingState;
        PaymentCenterSampleCodes.billingStreet = quote.Contact__r.MailingStreet;
        PaymentCenterSampleCodes.cardNumber = quote.Credit_Card_Number__c;
        PaymentCenterSampleCodes.expMonth = '12';
        PaymentCenterSampleCodes.expYear = '2021';
        PaymentCenterSampleCodes.firstName = quote.Contact__r.FirstName;
        PaymentCenterSampleCodes.lastName = quote.Contact__r.LastName;
        PaymentCenterSampleCodes.paymentName = quote.Name;
        PaymentResponse res =  PaymentCenterSampleCodes.payNow();
        System.debug(res);
        if(res.IsSuccessful == false)
        {
            throw new UtilityException(res.Message); 
        } 
        else if(res.IsSuccessful == true)
        {
            if(!Test.isRunningTest()){
            	throw new UtilityException('Success transaction.'); 
            }
        } 
    }
    @AuraEnabled    
    public static Registrations__c getRecordDetails(String recordId)
    {
        Registrations__c reg = [Select Id,Name,First_Name__c,Last_Name__c,Email__c,Amount__c,
                                Mobile__c,Street__c,City__c,State_Providence__c,Postal_Code__c,
                                Credit_Card_Number__c,Exp_Date__c,
                                CVV__c
                                FROM Registrations__c 
WHERE Id=:recordId LIMIT 1];
return reg;
}*/
    @AuraEnabled
    public static PaymentResponse processPayment(Decimal amount,String cardNumber,String expMonth,String expYear, String CVV,
                                                 String billingStreet,String billingCity,String billingState,
                                                 String billingPostalCode,
                                                 String billingCountry,String billingEmail,String billingFirstName,
                                                 String billingLastName,
                                                 String paymentName, String description)
    { 
        PaymentCenterSampleCodes.amount = amount;
        PaymentCenterSampleCodes.billingStreet = billingStreet;
        PaymentCenterSampleCodes.billingCity = billingCity;
        PaymentCenterSampleCodes.billingState = billingState;
        PaymentCenterSampleCodes.billingPostalCode = billingPostalCode;
        PaymentCenterSampleCodes.billingCountry = billingCountry;
        PaymentCenterSampleCodes.billingEmail = billingEmail;
        
        
        
        PaymentCenterSampleCodes.cardNumber = cardNumber;
        PaymentCenterSampleCodes.expMonth = expMonth;
        PaymentCenterSampleCodes.expYear = expYear;
        PaymentCenterSampleCodes.CVV = CVV;
        PaymentCenterSampleCodes.firstName = billingFirstName;
        PaymentCenterSampleCodes.lastName = billingFirstName;
        PaymentCenterSampleCodes.paymentName = paymentName;
        PaymentCenterSampleCodes.description = description;
        return PaymentCenterSampleCodes.payNow();
    }
}