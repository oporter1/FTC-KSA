public class TransferPaymentController {

    @AuraEnabled
    public static List<fw1__Invoice__c> getOtherInvoice(Id invoiceId, Id accountId, Id contactId) {
        return new List<fw1__Invoice__c>([SELECT Name, fw1__Balance_Due__c, fw1__Due_Date__c
                                            FROM fw1__Invoice__c
                                           WHERE id !=: invoiceId
                                             //AND fw1__Account__c =: accountId
                                             //AND fw1__Contact__c =: contactId
                                             AND fw1__Balance_Due__c > 0
                                        ORDER BY fw1__Due_Date__c]);
    }

    @AuraEnabled
    public static void transferPayment(Request req){

        Savepoint sp = Database.setSavepoint();
        Decimal amountForTransfer = req.amount;
        try {

            Map<Id, fw1__Invoice__c> invoiceMap = new Map<Id, fw1__Invoice__c>();
            Map<Id, fw1__Payment__c> oldPaymentMap = new Map<Id, fw1__Payment__c>();
            List<fw1__Payment_Activity__c> paymentActivityList = new List<fw1__Payment_Activity__c>();
            // update old invoice
            fw1__Invoice__c oldInvoice = req.inv;
            oldInvoice.fw1__Total_Paid_Amount__c = req.inv.fw1__Total_Paid_Amount__c - req.amount;
            invoiceMap.put(oldInvoice.Id, oldInvoice);

            // void payment of current invoice
            for(fw1__Payment__c payment: [SELECT fw1__Total_Paid_Amount__c,
                                                 fw1__Total_Captured_Amount__c,
                                                 fw1__Total_Refunded_Amount__c,
                                                 fw1__Transaction_ID__c,
                                                 fw1__Reconciliation_ID__c
                                            FROM fw1__Payment__c
                                           WHERE fw1__Invoice__c =: req.inv.Id
                                             AND fw1__Total_Paid_Amount__c != 0]){

                // create payment activity
                fw1__Payment_Activity__c paymentActivity = new fw1__Payment_Activity__c();
                paymentActivity.Name = 'Void';
                paymentActivity.fw1__Payment__c = payment.Id;
                paymentActivity.fw1__Transaction_Date__c = Datetime.now();
                paymentActivity.fw1__Transaction_ID__c = payment.fw1__Transaction_ID__c;
                paymentActivity.fw1__Reconciliation_ID__c = payment.fw1__Reconciliation_ID__c;
                paymentActivity.fw1__Note__c = 'Transfer Payment';
                paymentActivity.fw1__Invoice__c = oldInvoice.Id;
                paymentActivity.fw1__Amount__c = payment.fw1__Total_Paid_Amount__c;
                paymentActivityList.add(paymentActivity);

                // void payment
                payment.fw1__Status__c = 'Voided';
                payment.fw1__Amount__c = 0;
                oldPaymentMap.put(payment.Id, payment);
            }

            // get all invoice, based from nearest due date
            List<fw1__Payment__c> newPaymentList = new List<fw1__Payment__c>();
            for(fw1__Invoice__c inv: [SELECT Name, fw1__Account__c, fw1__Contact__c, fw1__Balance_Due__c, fw1__Total_Paid_Amount__c
                                        FROM fw1__Invoice__c
                                        WHERE Id IN: req.toInvoiceIds
                                    ORDER BY fw1__Due_Date__c]){
                // check balance, create new payment
                if(amountForTransfer > 0){
                    fw1__Payment__c payment = new fw1__Payment__c();
                    payment.Name = 'Payment for ' + inv.Name;
                    payment.fw1__Invoice__c = inv.Id;
                    payment.fw1__Account__c = inv.fw1__Account__c;
                    payment.fw1__Contact__c = inv.fw1__Contact__c;
                    payment.fw1__Payment_Date__c = Datetime.now();
                    payment.fw1__Type__c = '';
                    payment.fw1__Payment_Method__c = 'Payment Transfer';
                    payment.fw1__Reference__c = req.inv.Name;

                    // set payment amount
                    payment.fw1__Amount__c = amountForTransfer >= inv.fw1__Balance_Due__c
                                            ? inv.fw1__Balance_Due__c
                                            : amountForTransfer;

                    amountForTransfer -= payment.fw1__Amount__c;
                    newPaymentList.add(payment);

                    // update new invoice
                    inv.fw1__Total_Paid_Amount__c += payment.fw1__Amount__c;
                    invoiceMap.put(inv.Id, inv);
                }
            }

            // create payment if there is a difference from the paid amount and transfered amount
            List<fw1__Payment__c> paymentList = new List<fw1__Payment__c>();
            fw1__Payment__c excessPayment = new fw1__Payment__c();
            oldInvoice.fw1__Total_Paid_Amount__c += amountForTransfer;
            if(oldInvoice.fw1__Total_Paid_Amount__c > 0){
                excessPayment.fw1__Invoice__c = oldInvoice.Id;
                excessPayment.Name = 'Payment of ' + req.inv.Name;
                excessPayment.fw1__Account__c = req.acc.Id;
                excessPayment.fw1__Contact__c = req.con.Id;
                excessPayment.fw1__Amount__c = oldInvoice.fw1__Total_Paid_Amount__c;
                excessPayment.fw1__Payment_Date__c = Datetime.now();
                excessPayment.fw1__Type__c = 'Cash';
                excessPayment.fw1__Email_Currency_Symbol__c = req.inv.fw1__Email_Currency_Symbol__c;
                paymentList.add(excessPayment);
            }

            paymentList.addAll(oldPaymentMap.values());
            paymentList.addAll(newPaymentList);
            if(!paymentList.isEmpty()) upsert paymentList;

            // create payment activity for excess payment
            if(excessPayment.Id != null){
                fw1__Payment_Activity__c excessPaymentActivity = new fw1__Payment_Activity__c();
                excessPaymentActivity.Name = 'Invoice Payment';
                excessPaymentActivity.fw1__Payment__c = excessPayment.Id;
                excessPaymentActivity.fw1__Transaction_Date__c = Datetime.now();
                excessPaymentActivity.fw1__Note__c = 'Transfer Payment';
                excessPaymentActivity.fw1__Invoice__c = oldInvoice.Id;
                excessPaymentActivity.fw1__Amount__c = excessPayment.fw1__Amount__c;
                paymentActivityList.add(excessPaymentActivity);
            }
            
            for(fw1__Payment__c payment: newPaymentList){ // new invoice

                fw1__Payment_Activity__c paymentActivity = new fw1__Payment_Activity__c();
                paymentActivity.Name = 'Invoice Payment';
                paymentActivity.fw1__Amount__c = payment.fw1__Amount__c;
                paymentActivity.fw1__Invoice__c = payment.fw1__Invoice__c;
                paymentActivity.fw1__Applied_To_Invoice__c = true;
                paymentActivity.fw1__Payment__c = payment.Id;
                paymentActivity.fw1__Transaction_Date__c = payment.fw1__Payment_Date__c;

                paymentActivityList.add(paymentActivity);
            }

            /****** PROCESS INSTALLMENTS *******/
            List<fw1__Installment__c> installmentList = new List<fw1__Installment__c>();
            installmentList.addAll(processOldInvInstallment(oldInvoice, excessPayment)); // old installment
            installmentList.addAll(processNewInvoiceInstallment(newPaymentList)); // new installment

            if(!paymentActivityList.isEmpty()) insert paymentActivityList;
            if(!installmentList.isEmpty()) upsert installmentList;

            /******* RECALCULATE INSTALLMENT AMOUNT ************/
            for(fw1__Installment__c install: installmentList){
                if(install.fw1__Installment_Date__c <= Date.Today()
                    && install.fw1__Balance_Due__c > 0){
                    Id invId = oldInvoice.Id;
                    // by pass issue on soql
                    try{
                        if(String.isNotBlank(install.fw1__Invoice__c))
                            invId = install.fw1__Invoice__c;
                    } catch (exception e){}
                    invoiceMap.get(invId).fw1__Due_Installment_Amount__c = install.fw1__Balance_Due__c;
                }
            }
            if(!invoiceMap.isEmpty()) update invoiceMap.values();
        }
        catch (Exception e) {
            // rollback database incase of failure
            Database.rollback( sp );
            throw new AuraHandledException(e.getMessage());
        }
    }

    public class Request {
        @AuraEnabled public List<Id> toInvoiceIds {get;set;}
        @AuraEnabled public Decimal amount {get;set;}
        @AuraEnabled public Account acc {get;set;}
        @AuraEnabled public Contact con {get;set;}
        @AuraEnabled public fw1__Invoice__c inv {get;set;}
    }

    public static List<fw1__Installment__c> processOldInvInstallment(fw1__Invoice__c inv, fw1__Payment__c excessPayment){
        List<fw1__Installment__c> installmentList = new List<fw1__Installment__c>();
        
        Decimal totalPaidAmount = 0;
        if(excessPayment.Id != null){
            totalPaidAmount = excessPayment.fw1__Amount__c;
        }
        for(fw1__Installment__c install: [SELECT fw1__Installment_Date__c, fw1__Balance_Due__c, fw1__Total_Installment_Amount__c, fw1__Paid_Amount__c
                                            FROM fw1__Installment__c
                                           WHERE fw1__Invoice__c =: inv.Id
                                        ORDER BY fw1__Installment_Date__c ASC]){
            
            if(excessPayment.Id == null){
                install.fw1__Paid_Amount__c = 0;
            }
            else {
                if(totalPaidAmount >= install.fw1__Total_Installment_Amount__c){
                    install.fw1__Paid_Amount__c = install.fw1__Total_Installment_Amount__c;
                }
                else {
                    install.fw1__Paid_Amount__c = totalPaidAmount;
                }
            }
            install.recalculateFormulas();
            
            // relink installment to the new payment
            install.fw1__Payment__c = null;
            if(excessPayment.Id != null
                && install.fw1__Paid_Amount__c > 0){
                install.fw1__Payment__c = excessPayment.Id;
            }
            installmentList.add(install);

            totalPaidAmount -= install.fw1__Paid_Amount__c;
        }

        return installmentList;
    }

    public static List<fw1__Installment__c> processNewInvoiceInstallment(List<fw1__Payment__c> newPaymentList){
        List<fw1__Installment__c> installmentList = new List<fw1__Installment__c>();

        Map<Id, Id> invPayMap = new Map<Id, Id>();
        Map<Id, Decimal> paymentBalanceMap = new Map<Id, Decimal>();

        for(fw1__Payment__c pay: newPaymentList){
            invPayMap.put(pay.fw1__Invoice__c, pay.Id);
            paymentBalanceMap.put(pay.Id, pay.fw1__Amount__c);
        }

        for(fw1__Installment__c install: [SELECT fw1__Paid_Amount__c, fw1__Balance_Due__c, fw1__Invoice__c, fw1__Installment_Date__c
                                            FROM fw1__Installment__c
                                           WHERE fw1__Invoice__c IN :invPayMap.keySet()
                                             AND fw1__Balance_Due__c > 0
                                        ORDER BY fw1__Invoice__r.fw1__Invoice_Date__c, fw1__Installment_Date__c ASC]){

            install.fw1__Payment__c = invPayMap.get(install.fw1__Invoice__c);
            install.fw1__Paid_Amount__c = paymentBalanceMap.get(install.fw1__Payment__c) > install.fw1__Balance_Due__c
                                        ? install.fw1__Balance_Due__c
                                        : paymentBalanceMap.get(install.fw1__Payment__c);

            if(install.fw1__Paid_Amount__c <= 0){
                install.fw1__Payment__c = null;
            }
            else {
                paymentBalanceMap.put(install.fw1__Payment__c, paymentBalanceMap.get(install.fw1__Payment__c) - install.fw1__Paid_Amount__c);
            }

            installmentList.add(install);
        }
        return installmentList;
    }
}