@isTest
public class KSA_ControllerTest {
   /* @isTest static void loadRegistrationWrapperTest() {
        KSA_RelationshipNames__c relationshipCs = new KSA_RelationshipNames__c();
        relationshipCs.Name = 'Coach';
        relationshipCs.RelationshipName__c = 'Coach';
        insert relationshipCs;
        
        KSA_ShirtSizes__c shirtSizeCs = new KSA_ShirtSizes__c();
        shirtSizeCs.Name = 'Small - $25.00';
        shirtSizeCs.ShirtSize__c = 'Small - $25.00';
        insert shirtSizeCs;
        
        KSA_SportsNames__c sportsNameCs = new KSA_SportsNames__c();
        sportsNameCs.Name = 'Baseball';
        sportsNameCs.SportName__c = 'Baseball';
        insert sportsNameCs;
        
        KSA_StageNames__c stageNameCs = new KSA_StageNames__c();
        stageNameCs.Name = '1';
        stageNameCs.StageName__c = 'Contact Information';
        insert stageNameCs;
        
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
        Quote__c qte1 = new Quote__c(Contact__c=ct.Id,Card_Type__c='American Express',Credit_Card_Number__c='370000000000002',CVV__c='000',
                                     Exp_Date__c='',Opportunity__c=opId1.Id,Paid_Amount__c=1999.0);
        insert qte1;
        system.debug('qte id: '+qte);
        
        fw1__Invoice__c invoice = new fw1__Invoice__c();
        invoice.Quote__c = qte.Id;
        invoice.fw1__Opportunity__c = opId1.Id;
        invoice.fw1__Payment_Plan__c = pyt.Id;
        
        fw1__Installment__c paidInstallment = new fw1__Installment__c();
        paidInstallment.Opportunity__c = opId.Id;
        paidInstallment.Quote__c = qte.Id;
        paidInstallment.Plan_Installment__c = plan1.Id;
        paidInstallment.fw1__Installment_Amount__c = 1000;
        paidInstallment.fw1__Installment_Date__c = System.today();
       	paidInstallment.fw1__Invoice__c = invoice.Id;

        RecordType rt = [SELECT Id FROM RecordType WHERE sObjectType = 'Registrations__c' AND Name = 'ATHLETE'];
        Product2 prod = new Product2(Name = 'Laptop X200',Family = 'Hardware',Description='HjhJHjsds sdss',Sales_Price__c=33.33,
                                     Room_Type__c='2');
        insert prod;
        
        String productGroupRecId = Schema.SObjectType.Event_Group_Package__c.getRecordTypeInfosByDeveloperName().get('Product_Package').getRecordTypeId();
        String RGPRecId = Schema.SObjectType.Event_Group_Package__c.getRecordTypeInfosByDeveloperName().get('RGP').getRecordTypeId();
        String addOnRecId = Schema.SObjectType.Event_Group_Package__c.getRecordTypeInfosByDeveloperName().get('Product_Add_On').getRecordTypeId();
        String AirfareRecId = Schema.SObjectType.Event_Group_Package__c.getRecordTypeInfosByDeveloperName().get('Airfare').getRecordTypeId();
        
        
        Event_Group_Package__c eventGP  = new Event_Group_Package__c(Product__c=prod.Id,Team_Opportunity__c=opId.Id,RecordTypeId=productGroupRecId);
        Event_Group_Package__c rgp  = new Event_Group_Package__c(Product__c=prod.Id,Team_Opportunity__c=opId.Id,RecordTypeId=RGPRecId);
        Event_Group_Package__c addOn  = new Event_Group_Package__c(Product__c=prod.Id,Team_Opportunity__c=opId.Id,RecordTypeId=addOnRecId);
        Event_Group_Package__c airfair  = new Event_Group_Package__c(Product__c=prod.Id,Team_Opportunity__c=opId.Id,RecordTypeId=AirfareRecId);
        insert eventGP; 
        insert rgp;
        insert addOn;
        insert airfair;
        eventGP = [select Id,Room_Size__c,Sales_Price__c from Event_Group_Package__c where Id=:eventGP.Id];
        System.assertNotEquals(null, eventGP.Room_Size__c);
        System.assertNotEquals(null, eventGP.Sales_Price__c); 
        Registrations__c regt = new Registrations__c(Quote__c=qte.Id,School_Name__c='Sch name',Webcode__c='100',
                                                     Sport__c='Baseball',First_Name__c='Fname',Last_Name__c='Lname',Middle_Name__c='Mname',Gender__c='Male',
                                                     Birth_Date__c=Date.newinstance(2010, 2, 17),Mobile__c='1212',Email__c='email@test.com',
                                                     Shirt_Size_25__c='Small - $25.00',Relationship_to_Athlete__c='Self',Room_No__c=1,
                                                     Contact__c=ct.Id,recordtypeid=rt.Id);
        
        String TAGRecId = Schema.SObjectType.Registrations__c.getRecordTypeInfosByDeveloperName().get('TAG').getRecordTypeId();
        Registrations__c regtTAG = new Registrations__c(Quote__c=qte.Id,School_Name__c='Sch name',Webcode__c='100',
                                                     Sport__c='Baseball',Last_Name__c='Lname',Middle_Name__c='Mname',Gender__c='Male',
                                                     Birth_Date__c=Date.newinstance(2010, 2, 17),Mobile__c='1212',Email__c='email@test.com',
                                                     Shirt_Size_25__c='Small - $25.00',Relationship_to_Athlete__c='Self',Room_No__c=1,
                                                     Contact__c=ct.Id,recordtypeid=TAGRecId);
        insert regt;
        insert regtTAG;
        
        Registration_Line_Item__c quoteRegLines = new Registration_Line_Item__c(Event_Group_Product__c=Id.valueOf(eventGP.Id),Amount__c=100,Quantity__c=1,
                                                                                Registration__c=regt.Id,Quote__c=qte.Id,To__c=Date.newinstance(2020, 2, 17),
                                                                                From__c=Date.newinstance(2010, 2, 17));
        
        
        
        insert quoteRegLines;
        
        Room room1 = new Room();
        room1.eventPackage = eventGP;
        room1.packageQuantity=2;
        room1.persons=new List<Registrations__c>{regt};
            room1.roomNo=1;
        room1.selectedpersonsCount=2;
        Room room2 = new Room();
        room2.eventPackage = eventGP;
        room2.packageQuantity=2;
        room2.persons=new List<Registrations__c>{regt};
            room2.roomNo=1;
        room2.selectedpersonsCount=2;
        List<Room> roomList = new List<Room>();
        roomList.add(room1);
        roomList.add(room2);
        List<Room> roomList1 = new List<Room>();
        roomList.add(room1);    
        
        KSAQuote ksaq = new KSAQuote();
        ksaq.pckg=eventGP;
        ksaq.packageId=eventGP.Id;
        ksaq.packageName='Pname';
        ksaq.packageQuantity=1;
        ksaq.addOnSubTotal=100;
        ksaq.isAddon=false;
        ksaq.isSelected=true;
        ksaq.fromDate=Date.newinstance(2020, 2, 17);
        ksaq.toDate=Date.newinstance(2020, 2, 27);
        ksaq.rooms=roomList;
        ksaq.regLineItem = quoteRegLines;
        
        KSAQuote ksaq1 = new KSAQuote();
        ksaq1.pckg=eventGP;
        ksaq1.packageId=eventGP.Id;
        ksaq1.packageName='Pname';
        ksaq1.packageQuantity=1;
        ksaq1.addOnSubTotal=100;
        ksaq1.isAddon=true;
        ksaq1.isSelected=true;
        ksaq1.fromDate=Date.newinstance(2020, 2, 17);
        ksaq1.toDate=Date.newinstance(2020, 2, 27);
        ksaq1.rooms=roomList;
        ksaq1.regLineItem = quoteRegLines;
        KSAQuote ksaq2 = new KSAQuote();
        ksaq2.pckg=eventGP;
        ksaq2.packageId=eventGP.Id;
        ksaq2.packageName='Pname';
        ksaq2.packageQuantity=1;
        ksaq2.addOnSubTotal=100;
        ksaq2.isAddon=false;
        ksaq2.isSelected=true;
        ksaq2.fromDate=Date.newinstance(2020, 2, 17);
        ksaq2.toDate=Date.newinstance(2020, 2, 27);
        ksaq2.rooms=roomList1;
        
        List<KSAQuote> ksaqtList = new List<KSAQuote>();
        ksaqtList.add(ksaq);
        ksaqtList.add(ksaq1);
        RegistrationWrapper regWrp = new RegistrationWrapper();
        regWrp.con = ct;
        regWrp.quote = qte;
        regWrp.reg = regt;
        
        Test.startTest();
        KSA_Controller.loadRegistrationWrapper(qte.Id);
        KSA_Controller.loadRegistrationWrapper(null);
        KSA_Controller.loadPackageDetails(opId.KSA_Webcode__c, qte.Id);
        KSA_Controller.loadPackageDetails('', qte1.Id);
        KSA_Controller.loadRoomPackages('', String.valueOf(qte.Id), 1, 1);
        KSA_Controller.loadRoomPackages('', null, 1, 1);
        KSA_Controller.getEventLineItems(qte.Id);
        KSA_Controller.getQuoteRegistrations(qte.Id);
        KSA_Controller.getEventQuoteRegistrations('', qte.Id);
        KSA_Controller.hasUserDetails('fff1223@test.com', opId.KSA_Webcode__c);
        
        KSA_Controller.removeRoom(JSON.serialize(ksaq), 1);
        
        KSA_Controller.createNewRoom(JSON.serialize(ksaq), 2);
        KSA_Controller.createNewRoom(JSON.serialize(ksaq2), 1);
        KSA_Controller.createNewCoachRoom(JSON.serialize(ksaq), JSON.serialize(regWrp), 1, false);
        KSA_Controller.getStageNames();
        KSA_Controller.getSportsNames();
        KSA_Controller.getRelationshipsNames();
        KSA_Controller.getShirtSizes();
        KSA_Controller.loadSchoolEventSport(opId.KSA_Webcode__c);
        
        List<KSAPaymentSchedule> paymentSchedules = KSA_Controller.getOpportunityPaymentSchedules(qte1.Id, opId.KSA_Webcode__c, JSON.serialize(ksaqtList), true);
        KSA_Controller.getOpportunityPaymentSchedules(qte1.Id, opId.KSA_Webcode__c, JSON.serialize(ksaqtList), false);
        
        KSA_Controller.processQuotePayment(false, opId.KSA_Webcode__c, JSON.serialize(paymentSchedules), JSON.serialize(ksaqtList), JSON.serialize(regWrp), false, 'Athlete');
        KSA_Controller.processQuotePayment(true, opId.KSA_Webcode__c, JSON.serialize(paymentSchedules), JSON.serialize(ksaqtList), JSON.serialize(regWrp), true, 'Athlete');
        KSA_Controller.processQuotePayment(false, opId.KSA_Webcode__c, JSON.serialize(paymentSchedules), JSON.serialize(ksaqtList), JSON.serialize(regWrp), true, 'Athlete');
        try {
        	KSA_Controller.createInvoice(opId, new Quote__c(), ct, new fw1__Payment__c(), new List<fw1__Invoice_Line__c>(), new List<KSAPaymentSchedule>(), false);  
            insert invoice;
            fw1__Installment__c inst = new fw1__Installment__c();
            inst.Name = 'Test';
            inst.fw1__Installment_Date__c = System.today().addDays(10);
            inst.fw1__Installment_Amount__c = 10000;
            inst.fw1__Invoice__c=invoice.id;
            insert inst;
        } catch(Exception ex) {
            
        }
        
        Test.stopTest();
    }*/
}