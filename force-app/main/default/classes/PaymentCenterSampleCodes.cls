public without sharing class PaymentCenterSampleCodes {
    public static Decimal amount;
    public static String firstName;
    public static String lastName;
    public static String cardNumber;//'4111111111111111'
    public static String expMonth;
    public static String expYear;
    public static String CVV;
    public static String billingStreet;
    public static String billingCity;
    public static String billingState;
    public static String billingPostalCode;
    Public static String billingCountry = 'US';
    public static String billingEmail;  
    public static String paymentName;    
    public static String description; 
    
    public static PaymentResponse payNow() {
        PaymentResponse res = new PaymentResponse();
        try{
            
            // formulate payment request, data here will normally come from your own interface
            fw1__Payment__c payment = formulatePaymentRequest();
            
            // submit payment to processor (the actual callout happens here)
            fw1.ProcessorResponseModel response = doPayment(payment);
            
            // parse response
            if (response.IsSuccessful) {
                // payment has been processed successfully by the processor and a payment record is created in Salesforce
                System.debug('Payment ID in Salesforce: ' + response.ReferenceId);
                response.Message = 'SUCCESS';
                res.payment = payment;
                res.Message = response.Message;
                res.IsSuccessful = true;
            }
            else {
                // payment has failed, no payment record has been created in Salesforce
                System.debug('Payment Failure Reason: ' + response.Message);
                res.payment = payment;
                res.Message = response.Message;
                res.IsSuccessful = false;
            }
            
            return res;
        }
        catch(Exception e)
        {
            System.debug('Payment Failure Reason:Exception ' + e.getStackTraceString());
            res.payment = null;
            res.Message = e.getMessage();
            res.IsSuccessful = false;
            return res;
        }
    }
    
    
  private static fw1__Payment__c formulatePaymentRequest() {
        
        fw1__Payment__c payment = new fw1__Payment__c();
        
        payment.fw1__Payment_Processor__c = getDefaultPaymentProcessor();
        payment.fw1__API_Payment__c = true;
        payment.fw1__Payment_Method__c = 'Credit Card';
        payment.fw1__Type__c = 'Charge'; // possible values: Charge/Authorization
        payment.fw1__Payment_Date__c = System.Now();
        
        // THE FOLLOWING DATA WOULD NORMALLY COME FROM YOUR INTERFACE
        
        payment.Name = paymentName; // any name to identify the payment
        payment.fw1__Amount__c = amount; // amount to charge
        payment.fw1__Email_Currency_Symbol__c = '$';
        payment.fw1__Credit_Card_Type__c = 'Visa';
        payment.fw1__First_Name__c = firstName;
        payment.fw1__Last_Name__c = lastName;
        payment.fw1__Credit_Card_Number__c = cardNumber;//'4242424242424242';//4111111111111111
        payment.fw1__Expiry_Month__c = expMonth;
        payment.fw1__Expiry_Year__c = expYear;
      	//payment.fw1__CVV2__c = CVV;
      	//payment.fw1__CVV2_Match__c = CVV;
        payment.fw1__Billing_Street__c = billingStreet;
        payment.fw1__Billing_City__c = billingCity;
        payment.fw1__Billing_State__c = billingState;
        payment.fw1__Billing_Zip__c = billingPostalCode;
        payment.fw1__Billing_Country__c = 'US';
        payment.fw1__Email__c = billingEmail; // optional, if populated a receipt will be sent to this email
        payment.Description__c = description;
        // You can optionally attach the payment to an account, contact or opportunity by populating the fields below
        
        // payment.fw1__Account__c = 
        // payment.fw1__Contact__c = 
        // payment.fw1__Opportunity__c = 
        
        return payment;
    } 
    private static String getDefaultPaymentProcessor() {
        String defaultPaymentProcessor = '';
        
        fw1__Payment_Processor__c pProcessor = new fw1__Payment_Processor__c();
        try {
            pProcessor = [SELECT Name
                          FROM fw1__Payment_Processor__c
                          WHERE fw1__Use_As_Default__c = true
                          LIMIT 1];
            defaultPaymentProcessor = pProcessor.Name;
        } catch (Exception e) {
            System.Debug('There is no default Payment Processor: ' + e);
            try {
                pProcessor = [SELECT Name
                              FROM fw1__Payment_Processor__c
                              LIMIT 1];
                defaultPaymentProcessor = pProcessor.Name;
            } catch (Exception ex) {
                defaultPaymentProcessor = '';
                System.Debug('There are no Payment Processors.' + ex);
            }
        }
        return defaultPaymentProcessor;
    }
    
    
    private static fw1.ProcessorResponseModel doPayment(fw1__Payment__c payment) {
        fw1.ProcessorResponseModel response = new fw1.ProcessorResponseModel();
        
        response.IsSuccessful = fw1.PaymentProcessor.doPayment(payment);
        response.ReferenceId = payment.Id;
        response.Message = payment.fw1__Payment_Result__c;
        response.ErrorType = payment.fw1__Error_Type__c;
        response.ErrorCode = payment.fw1__Error_Code__c;
        
        return response;
    }
}