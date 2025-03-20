public without sharing class PayInvoiceInvocable {

    @InvocableMethod(label='Pay Now')
    public static List<ProcessorResponseOutput> payNow(List<PaymentInput> paymentInputs) {
        List<ProcessorResponseOutput> outputResponses = new List<ProcessorResponseOutput>();

        for (PaymentInput paymentInput : paymentInputs) {
            ProcessorResponseOutput output = new ProcessorResponseOutput();

            try {
                // Formulate payment request using paymentInput
                fw1__Payment__c payment = formulatePaymentRequest(paymentInput);

                // Submit payment to processor (the actual callout happens here)
                fw1.ProcessorResponseModel response = doPayment(payment);

                // Parse response
                if (response.IsSuccessful) {
                    // Payment has been processed successfully by the processor and a payment record is created in Salesforce
                    System.debug('Payment ID in Salesforce: ' + response.ReferenceId);
                    output.PaymentResult = response.Message;
                    output.PaymentId = response.ReferenceId;
                    output.ErrorType = response.ErrorType; 
                    output.ErrorCode = response.ErrorCode; 
                } else {
                    // Payment has failed, no payment record has been created in Salesforce
                    System.debug('Payment Failure Reason: ' + response.Message);
                    output.ErrorMessage = response.Message; 
                    output.ErrorType = response.ErrorType; 
                    output.ErrorCode = response.ErrorCode;
                }
            } catch (Exception ex) {
                System.debug('An error occurred: ' + ex.getMessage());
                output.ErrorMessage = ex.getMessage(); 
            }

            outputResponses.add(output);
        }

        return outputResponses;
    }

    public static fw1__Payment__c formulatePaymentRequest(PaymentInput paymentInput) {
        fw1__Payment__c payment = new fw1__Payment__c();
        payment.fw1__Payment_Processor__c = getDefaultPaymentProcessor();
        payment.fw1__API_Payment__c = true;
        payment.fw1__Payment_Method__c = 'Credit Card';
        payment.fw1__Type__c = 'Charge';
        payment.fw1__Payment_Date__c = System.Now();
        payment.Name = paymentInput.Name;
        payment.fw1__Amount__c = paymentInput.Amount;
        payment.fw1__Email_Currency_Symbol__c = '$';
        payment.fw1__Credit_Card_Type__c = paymentInput.CreditCardType;
        payment.fw1__First_Name__c = paymentInput.FirstName;
        payment.fw1__Last_Name__c = paymentInput.LastName;
        payment.fw1__Credit_Card_Number__c = paymentInput.CreditCardNumber;
        payment.fw1__Expiry_Month__c = paymentInput.ExpiryMonth;
        payment.fw1__Expiry_Year__c = paymentInput.ExpiryYear;
        payment.fw1__Billing_Street__c = paymentInput.BillingStreet;
        payment.fw1__Billing_City__c = paymentInput.BillingCity;
        payment.fw1__Billing_State__c = paymentInput.BillingState;
        payment.fw1__Billing_Zip__c = paymentInput.BillingZip;
        payment.fw1__Billing_Country__c = 'US';
        payment.fw1__Email__c = paymentInput.Email;
        payment.fw1__Opportunity__c = paymentInput.oppId;
        payment.fw1__Invoice__c = paymentInput.invoiceId;
        payment.fw1__Auto_BillPay__c = paymentInput.autoPay;
        payment.fw1__Credit_Card_Surcharge_Amount__c = paymentInput.creditCardFee;
        payment.fw1__Credit_Card_Surcharge_Label__c = paymentInput.creditCardLabel;
        payment.fw1__Pass_Surcharge_As_Service_Fee__c = paymentInput.surchargeIsServiceFee;

        return payment;
    }

   public static String getDefaultPaymentProcessor() {
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
           
        }
        return defaultPaymentProcessor;
    }


    public static fw1.ProcessorResponseModel doPayment(fw1__Payment__c payment) {
        fw1.ProcessorResponseModel response = new fw1.ProcessorResponseModel();
        response.IsSuccessful = fw1.PaymentProcessor.doPayment(payment);
        response.ReferenceId = payment.Id;
        response.Message = payment.fw1__Payment_Result__c;
        response.ErrorType = payment.fw1__Error_Type__c;
        response.ErrorCode = payment.fw1__Error_Code__c;
        return response;
    }

    public class PaymentInput {
        @InvocableVariable
        public String Name;
        @InvocableVariable
        public Decimal Amount;
        @InvocableVariable
        public String CreditCardType;
        @InvocableVariable
        public String FirstName;
        @InvocableVariable
        public String LastName;
        @InvocableVariable
        public String CreditCardNumber;
        @InvocableVariable
        public String ExpiryMonth;
        @InvocableVariable
        public String ExpiryYear;
        @InvocableVariable
        public String BillingStreet;
        @InvocableVariable
        public String BillingCity;
        @InvocableVariable
        public String BillingState;
        @InvocableVariable
        public String BillingZip;
        @InvocableVariable
        public String Email;
        @InvocableVariable
        public String oppId;
        @InvocableVariable
        public String invoiceId;
        @InvocableVariable
        public Boolean autoPay;
        @InvocableVariable
        public Decimal creditCardFee;
        @InvocableVariable
        public String creditCardLabel;
        @InvocableVariable
        public Boolean surchargeIsServiceFee;
    }

    public class ProcessorResponseOutput {
        @InvocableVariable
        public String PaymentResult;
        @InvocableVariable
        public String PaymentId;
        @InvocableVariable
        public String ErrorMessage;
        @InvocableVariable
        public String ErrorType;
        @InvocableVariable
        public String ErrorCode;
    }
}