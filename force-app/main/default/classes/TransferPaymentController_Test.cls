@isTest
public class TransferPaymentController_Test {
    
    @testSetup
    static void setup(){
        insert new fw1__Payment_Center_Setting__c(Name = 'Default Settings');
        fw1.PackagedData.restoreStripeData();

        // account
        Account acc = new Account(
                Name = 'Test Account'
            );
        insert acc;

        // contact
        Contact con = new Contact(
                AccountId = acc.Id,
                FirstName = 'First',
                LastName = 'Last',
                Email = 'test@test.com'
            );
        insert con;

        // invoice
        List<fw1__Invoice__c> invList = new List<fw1__Invoice__c>();
        fw1__Invoice__c inv = new fw1__Invoice__c(
                fw1__Alternate_Invoice_Number__c = 'Invoice 1',
                fw1__Account__c = acc.Id,
                fw1__Contact__c = con.Id,
                fw1__Invoice_Date__c = Date.today(),
                fw1__Email_Currency_Symbol__c = '$',
                fw1__Total_Paid_Amount__c = 1000
            );
        invList.add(inv);

        fw1__Invoice__c inv2 = new fw1__Invoice__c(
                fw1__Alternate_Invoice_Number__c = 'Invoice 2',
                fw1__Account__c = acc.Id,
                fw1__Contact__c = con.Id,
                fw1__Invoice_Date__c = Date.today(),
                fw1__Email_Currency_Symbol__c = '$'
            );
        invList.add(inv2);
        insert invList;

        // invoice lines
        List<fw1__Invoice_Line__c> invLines = new List<fw1__Invoice_Line__c>();
        invLines.add(new fw1__Invoice_Line__c(
                Name = 'inv 1',
                fw1__Invoice__c = inv.Id,
                fw1__Quantity__c = 2,
                fw1__Unit_Price__c = 500
            ));
        invLines.add(new fw1__Invoice_Line__c(
                Name = 'inv 2',
                fw1__Invoice__c = inv2.Id,
                fw1__Quantity__c = 4,
                fw1__Unit_Price__c = 500
            ));
        insert invLines;

        // payment
        fw1__Payment__c payment = new fw1__Payment__c(
                fw1__Payment_Method__c = 'Cash',
                fw1__Payment_Date__c = Date.today(),
                fw1__Amount__c = 1000,
                fw1__Invoice__c = inv.Id
            );
        insert payment;

        // installment
        List<fw1__Installment__c> installmentList = new List<fw1__Installment__c>();
        installmentList.add(new fw1__Installment__c(
                Name = 'Installment 1',
                fw1__Invoice__c = inv.Id,
                fw1__Installment_Amount__c = 500,
                fw1__Installment_Date__c = Date.today(),
                fw1__Payment__c = payment.Id
            ));
        installmentList.add(new fw1__Installment__c(
                Name = 'Installment 2',
                fw1__Invoice__c = inv.Id,
                fw1__Installment_Amount__c = 500,
                fw1__Installment_Date__c = Date.today(),
                fw1__Payment__c = payment.Id
            ));
        installmentList.add(new fw1__Installment__c(
                Name = 'Installment 1',
                fw1__Invoice__c = inv2.Id,
                fw1__Installment_Amount__c = 400,
                fw1__Installment_Date__c = Date.today()
            ));
        installmentList.add(new fw1__Installment__c(
                Name = 'Installment 2',
                fw1__Invoice__c = inv2.Id,
                fw1__Installment_Amount__c = 400,
                fw1__Installment_Date__c = Date.today()
            ));
        installmentList.add(new fw1__Installment__c(
                Name = 'Installment 3',
                fw1__Invoice__c = inv2.Id,
                fw1__Installment_Amount__c = 400,
                fw1__Installment_Date__c = Date.today()
            ));
        installmentList.add(new fw1__Installment__c(
                Name = 'Installment 4',
                fw1__Invoice__c = inv2.Id,
                fw1__Installment_Amount__c = 400,
                fw1__Installment_Date__c = Date.today()
            ));
        insert installmentList;
    }

    static testmethod void test1(){
        
        TransferPaymentController.Request request = new TransferPaymentController.Request();
        request.toInvoiceIds = new List<Id>();
        request.amount = 100;

        Set<Id> invIds = new Set<Id>();
        for(fw1__Invoice__c inv: [SELECT Name,
                                         fw1__Account__c,
                                         fw1__Contact__c,
                                         fw1__Contact__r.Name,
                                         fw1__Installment_Count__c,
                                         fw1__Total_Paid_Amount__c,
                                         fw1__Email_Currency_Symbol__c,
                                         fw1__Alternate_Invoice_Number__c
                                    FROM fw1__Invoice__c]){
            if(inv.fw1__Alternate_Invoice_Number__c == 'Invoice 1'){
                request.inv = inv;
            }
            else if(inv.fw1__Alternate_Invoice_Number__c == 'Invoice 2'){
                request.toInvoiceIds.add(inv.Id);
                request.acc = new Account(Id = inv.fw1__Account__c);
                request.con = new Contact(Id = inv.fw1__Contact__c);
            }
        }

        Test.startTest();
            TransferPaymentController.getOtherInvoice(request.inv.Id, request.acc.Id, request.con.Id);
            TransferPaymentController.transferPayment(request);
        Test.stopTest();
    }
}