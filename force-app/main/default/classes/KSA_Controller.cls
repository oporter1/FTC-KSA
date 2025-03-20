public without sharing class KSA_Controller  { 
    /*@AuraEnabled
    public static List<PickListWrapper> getStageNames() {
        List<PickListWrapper> lstPickListWrapper = new List<PickListWrapper>();
        for(KSA_StageNames__c ksaStageName : [Select Name, StageName__c from KSA_StageNames__c order by Name]) {
            PickListWrapper objPickListWrapper = new PickListWrapper();
            objPickListWrapper.value = ksaStageName.Name;
            objPickListWrapper.label = ksaStageName.StageName__c;
            lstPickListWrapper.add(objPickListWrapper);
        }
        
        return lstPickListWrapper;
    }
    
    @AuraEnabled
    public static List<PickListWrapper> getSportsNames() {
        List<PickListWrapper> lstPickListWrapper = new List<PickListWrapper>();
        for(KSA_SportsNames__c ksaSportName : [Select Name, SportName__c from KSA_SportsNames__c order by Name]) {
            PickListWrapper objPickListWrapper = new PickListWrapper();
            objPickListWrapper.value = ksaSportName.Name;
            objPickListWrapper.label = ksaSportName.SportName__c;
            lstPickListWrapper.add(objPickListWrapper);
        }
        
        return lstPickListWrapper;
    }
    
    @AuraEnabled
    public static List<PickListWrapper> getRelationshipsNames() {
        List<PickListWrapper> lstPickListWrapper = new List<PickListWrapper>();
        for(KSA_RelationshipNames__c ksaRelationshipName : [Select Name, RelationshipName__c from KSA_RelationshipNames__c order by Name]) {
            PickListWrapper objPickListWrapper = new PickListWrapper();
            objPickListWrapper.value = ksaRelationshipName.Name;
            objPickListWrapper.label = ksaRelationshipName.RelationshipName__c;
            lstPickListWrapper.add(objPickListWrapper);
        }
        return lstPickListWrapper;
    }
    
    @AuraEnabled
    public static List<PickListWrapper> getShirtSizes() {
        List<PickListWrapper> lstPickListWrapper = new List<PickListWrapper>();
        for(KSA_ShirtSizes__c ksaShirtSize : [Select Name, ShirtSize__c from KSA_ShirtSizes__c order by Name]) {
            PickListWrapper objPickListWrapper = new PickListWrapper();
            objPickListWrapper.value = ksaShirtSize.Name;
            objPickListWrapper.label = ksaShirtSize.ShirtSize__c;
            lstPickListWrapper.add(objPickListWrapper);
        }
        return lstPickListWrapper;
    }
    
    @AuraEnabled
    public static RegistrationWrapper loadRegistrationWrapper(String quoteId) {
        RegistrationWrapper wrapper = new RegistrationWrapper();
        if(quoteId != null) {
            Quote__c quote = [Select Id, Contact__c, Card_Type__c, Credit_Card_Number__c, CVV__c, Exp_Date__c, Opportunity__c,
                              Paid_Amount__c, Status__c, Quote_By__c FROM Quote__c WHERE ID = :quoteId]; 
            wrapper.quote = quote;
            
            if(quote.Contact__c != null) {
                wrapper.con = [Select Id, FirstName, LastName, Email, MobilePhone, MailingStreet, MailingCity, 
                               MailingState, MailingPostalCode FROM Contact Where ID = :quote.Contact__c];
                
                List<Registrations__c> athleteReg = [Select Id, Name, School_Name__c, Webcode__c, Sport__c, First_Name__c, 
                                                     Last_Name__c, Middle_Name__c, Gender__c, Birth_Date__c, Mobile__c, 
                                                     Email__c, Shirt_Size_25__c, Relationship_to_Athlete__c 
                                                     from Registrations__c where Quote__c = :quoteId 
                                                     AND RecordType.Name IN ('ATHLETE','COACH','TAG') 
                                                     AND Contact__c = :quote.Contact__c LIMIT 1];
                if(athleteReg.size() > 0) {
                    wrapper.reg = athleteReg[0];
                }
            }
        } else {
            wrapper.con = new Contact();
            wrapper.reg = new Registrations__c();
        }
        
        return wrapper;
    }
    
    @AuraEnabled
    public static List<KSAQuote> loadPackageDetails(String webcode, String quoteId) {
        Map<Id,Registration_Line_Item__c> quoteRegLinesMap = new Map<Id,Registration_Line_Item__c>();
        List<KSAQuote> eventPackages = new List<KSAQuote>();
        List<Opportunity> opps = [Select Id, AccountId, StageName, Closedate, Name FROM Opportunity 
                                  where KSA_Webcode__c = :webcode AND StageName != 'Closed Lost' LIMIT 1];
        
        if(quoteId != null) {
            quoteRegLinesMap = getEventLineItems(quoteId);//Quote Line Items to load.
        }

        if(!opps.isEmpty())  {
            List<Event_Group_Package__c> allWebcodeLineItems = [Select Id, Name, Room_Size__c, Product__r.Name, 
                                                                Product__r.Description, Sales_Price__c, Product__r.Image_ID__c,
                                                                Product__r.Family, Product__r.Image__c, 
                                                                RecordType.Name, Product__r.Room_Type__c, Description__c, 
                                                                Product__c, Product__r.Sales_Price__c FROM Event_Group_Package__c
                                                                Where KSA_Webcode__c = :webcode Order By RecordType.Name DESC];
            List<Id> prdId = new List<Id>();
            List<String> prName = new List<String>();
            
            if(!allWebcodeLineItems.isEmpty()) {
                for(Event_Group_Package__c item : allWebcodeLineItems) {
                    prdId.add(item.Product__c);
                    prName.add(item.Product__r.Name+'%');
                }
                
                List<Attachment> attIds = [select id, Parentid from Attachment where Parentid IN: prdId and Name like :prName];
                Map<id, String> actId = new Map<id, String>();
                
                for(Attachment atId :attIds) {
                    actId.put(atId.Parentid, atId.id);
                }

                for(Event_Group_Package__c item : allWebcodeLineItems) {
                    KSAQuote pck;
                    if(item.RecordType.Name=='Product Package') {
                        String attachIdval = '';
                        if(actId.get(item.Product__c) != null) {
                            attachIdval = actId.get(item.Product__c);
                        }
                        pck = new KSAQuote();
                        if(quoteRegLinesMap.containsKey(item.Id)) {
                            pck.isSelected = true;
                            pck.regLineItem = quoteRegLinesMap.get(item.Id);
                            pck.packageQuantity = Integer.valueOf(quoteRegLinesMap.get(item.Id).Quantity__c);
                        } else {
                            pck.isSelected = false;   
                            pck.regLineItem = new Registration_Line_Item__c();
                            pck.packageQuantity = 1;
                        }
                        
                        pck.packageId = item.Id;
                        pck.pckg = item;
                        pck.isAddon = false;
                    } else { //else if(item.RecordType.Name =='Product Add On')
                        pck = new KSAQuote();
                        if(quoteRegLinesMap.containsKey(item.Id)) {
                            pck.isSelected = true;
                            pck.regLineItem = quoteRegLinesMap.get(item.Id);
                            pck.packageQuantity = Integer.valueOf(quoteRegLinesMap.get(item.Id).Quantity__c);
                            pck.fromDate = quoteRegLinesMap.get(item.Id).From__c;
                            pck.toDate = quoteRegLinesMap.get(item.Id).To__c;
                        } else {
                            if(item.RecordType.Name == 'RGP') {
                                pck.isSelected = true;   
                            } else {
                                pck.isSelected = false;   
                            }
                            pck.regLineItem = new Registration_Line_Item__c();
                            pck.packageQuantity = 1;
                        }
                        pck.packageId = item.Id;
                        pck.pckg = item;
                        pck.isAddon = true; 
                    }
                    eventPackages.add(pck);
                }
            }
        }  
        return eventPackages;
    }
    
    @AuraEnabled
    public static String loadSchoolEventSport(String webcode) {
        List<Opportunity> opp = [Select Id, Name, AccountId, Account.Name, SportName__c, StageName, Closedate FROM Opportunity 
                                  where KSA_Webcode__c = :webcode AND StageName != 'Closed Lost' LIMIT 1];
        String strResponse = opp.get(0).Account.Name+'@@@'+opp.get(0).Name+'@@@'+opp.get(0).SportName__c;
        return strResponse;
    }
        
    @AuraEnabled
    public static List<Room> loadRoomPackages(String eventPacakgeId, String quoteId, Integer selectedLineRoomLimit, Integer selectedPacakgeQuantity) {
        KSAQuote pck = new KSAQuote(); 
        List<Room> rooms = new List<Room>();
        List<Registrations__c> allEventQuoteRegs = new List<Registrations__c>();
        if(quoteId != null && eventPacakgeId != null) {
            allEventQuoteRegs = getEventQuoteRegistrations(eventPacakgeId, quoteId);
        }
        
        for(Integer i = 1; i <= selectedPacakgeQuantity; i++) {
            List<Registrations__c> passengers = new List<Registrations__c>();
            Room room; 
            if(quoteId != null) {
                List<Registrations__c> roomRegistrations = new List<Registrations__c>();
                for(Registrations__c reg : allEventQuoteRegs)  {
                    if(reg.Room_No__c == i) {
                        room = new Room();
                        room.roomNo = i;
                        roomRegistrations.add(reg);    
                    }
                }
                if(roomRegistrations.size() > 0) {
                    room.persons = roomRegistrations;
                }
            } else {
                room = new Room();
                room.roomNo = i;
                for(Integer j = 1; j <= selectedLineRoomLimit; j++) {
                    Registrations__c newPassenger = new Registrations__c();
                    newPassenger.Room_No__c = i;
                    passengers.add(newPassenger);   
                }
                room.persons = passengers;
            }
            rooms.add(room);
        }
        pck.rooms = rooms;
        pck.packageQuantity = selectedPacakgeQuantity;
        return rooms;
    }
    
    @AuraEnabled
    public static KSAQuote createNewCoachRoom(String eventPck, String registrationWrapperJson, Integer selectedPacakgeQuantity, Boolean isAthlete) {
        KSAQuote selectedQuotePackage = (KSAQuote)JSON.deserialize(eventPck, KSAQuote.class);
        selectedQuotePackage.rooms = new List<Room>();
        RegistrationWrapper regWrapper = (RegistrationWrapper)JSON.deserialize(registrationWrapperJson, RegistrationWrapper.class);
        Contact POC = regWrapper.con;
        Registrations__c reg = regWrapper.reg;

        List<Room> newRooms = new List<Room>();
        List<Registrations__c> newRegistrations = new List<Registrations__c>();
        Room newRoom = new Room();
        newRoom.roomNo = 1;
        if(reg.First_Name__c != null) {
            reg.Room_No__c = 1;
            newRegistrations.add(reg);
        } else {
            Registrations__c newReg = new Registrations__c();
            newReg.First_Name__c = POC.FirstName;
            newReg.Last_Name__c = POC.LastName;
            newReg.Gender__c = reg.Gender__c;
            newReg.Shirt_Size_25__c = reg.Shirt_Size_25__c;
            newReg.Room_No__c = 1;
            newRegistrations.add(newReg);
        }
        
        if(isAthlete == false) {
            for(Integer j=1; j < selectedQuotePackage.pckg.Room_Size__c; j++) {
                Registrations__c newEmptyReg = new Registrations__c();
                newEmptyReg.Room_No__c = j;
                newRegistrations.add(newEmptyReg);
            }    
        }

        newRoom.persons = newRegistrations; 
        selectedQuotePackage.rooms.add(newRoom);

        return selectedQuotePackage;
    }
    
    @AuraEnabled
    public static KSAQuote createNewRoom(String eventPck, Integer selectedPacakgeQuantity) {
        KSAQuote selectedQuotePackage = (KSAQuote)JSON.deserialize(eventPck, KSAQuote.class);

        List<Room> newRooms = new List<Room>();
        for(Integer i = selectedQuotePackage.rooms.size() + 1; i <= selectedPacakgeQuantity; i++)  {
            Room newRoom = new Room();
            newRoom.roomNo = i;
            List<Registrations__c> newRegistrations = new List<Registrations__c>();
            System.debug(selectedQuotePackage.packageQuantity);
            for(Integer j = 0; j < selectedQuotePackage.pckg.Room_Size__c; j++) {
                Registrations__c newReg = new Registrations__c();
                newReg.Room_No__c = i;
                newRegistrations.add(newReg);
            }
            newRoom.persons = newRegistrations; 
            newRooms.add(newRoom);
        }
        selectedQuotePackage.rooms.addALL(newRooms);
        return selectedQuotePackage;
    }
    
    @AuraEnabled 
    public static KSAQuote removeRoom(String eventPck,Integer selectedPacakgeQuantity) {
        KSAQuote selectedQuotePackage = (KSAQuote)JSON.deserialize(eventPck, KSAQuote.class);
        for(Integer i = selectedPacakgeQuantity; i < selectedQuotePackage.rooms.size(); i++) {
            selectedQuotePackage.rooms.remove(i);
        }
        return selectedQuotePackage;
    }
    
    @AuraEnabled 
    public static List<KSAPaymentSchedule> getOpportunityPaymentSchedules(String quoteId, String webcode, String eventPackageListJson, Boolean isAthlete) {
        List<KSAPaymentSchedule> schedules = new List<KSAPaymentSchedule>();
        Decimal totalAmount = 0;
        List<KSAQuote> quotePackages = (List<KSAQuote>)JSON.deserialize(eventPackageListJson, List<KSAQuote>.class);
        for(KSAQuote quotePck : quotePackages) {
            if(quotePck.isSelected) {
                if(quotePck.isAddon) {
                    if(totalAmount == 0) {
                        totalAmount = quotePck.pckg.Sales_Price__c* quotePck.packageQuantity;
                    } else {
                        totalAmount = totalAmount + (quotePck.pckg.Sales_Price__c * quotePck.packageQuantity);                        
                    }    
                } else {
                    if(!isAthlete) {
                        if(totalAmount == 0) {
                            totalAmount = quotePck.pckg.Sales_Price__c* quotePck.packageQuantity * quotePck.pckg.Room_Size__c;
                        } else {
                            totalAmount = totalAmount + (quotePck.pckg.Sales_Price__c * quotePck.packageQuantity * quotePck.pckg.Room_Size__c);
                        }
                    } else {
                        if(totalAmount == 0) {
                            totalAmount = quotePck.pckg.Sales_Price__c* quotePck.packageQuantity;
                        } else {
                            totalAmount = totalAmount + (quotePck.pckg.Sales_Price__c * quotePck.packageQuantity);
                        }  
                    }
                }    
            }
        }
        
        Opportunity opp = [Select Id,Name,Payment_Plan__c from Opportunity where KSA_Webcode__c = :webcode LIMIT 1];
        List<fw1__Plan_Installment__c> shceduleInvoices = [Select Id,Name,fw1__Installment_Number__c,fw1__Installment_Date__c,
                                                           fw1__Installment_Percentage__c from fw1__Plan_Installment__c
                                                           where fw1__Payment_Plan__c = :opp.Payment_Plan__c order by fw1__Installment_Number__c];
        
        List<fw1__Installment__c> oppPaidInstallments = [Select Id,Name,Plan_Installment__c,fw1__Status__c, fw1__Balance_Due__c,fw1__Paid_Amount__c 
                                                         FROM fw1__Installment__c WHERE Opportunity__c = :opp.Id 
                                                         AND Quote__c = :quoteId AND Quote__c != null AND Opportunity__c != null];
        
        Map<Id,fw1__Installment__c> paidPlanInstallOppMap = new Map<Id,fw1__Installment__c>();
        
        for(fw1__Installment__c inst : oppPaidInstallments) {
            paidPlanInstallOppMap.put(inst.Plan_Installment__c, inst);
        }
        
        for(fw1__Plan_Installment__c plan : shceduleInvoices) {
            KSAPaymentSchedule ksaSchedule = new KSAPaymentSchedule();
            ksaSchedule.isSelected = false;
            ksaSchedule.planId = plan.Id;
            ksaSchedule.order = plan.fw1__Installment_Number__c;
            ksaSchedule.percent = plan.fw1__Installment_Percentage__c;
            ksaSchedule.scheduleDate = plan.fw1__Installment_Date__c;
            
            
            if(paidPlanInstallOppMap.size() > 0) {
                if(paidPlanInstallOppMap.containsKey(plan.Id)) {
                    if(paidPlanInstallOppMap.get(plan.Id).fw1__Status__c == 'PAID') {
                        ksaSchedule.isPaid = true;    
                        if(paidPlanInstallOppMap.get(plan.Id).fw1__Paid_Amount__c != null) {
                            ksaSchedule.amount = paidPlanInstallOppMap.get(plan.Id).fw1__Paid_Amount__c;
                        }
                    } else {
                        ksaSchedule.isPaid = false;
                        if(paidPlanInstallOppMap.get(plan.Id).fw1__Balance_Due__c != null) {
                            ksaSchedule.amount = paidPlanInstallOppMap.get(plan.Id).fw1__Balance_Due__c;
                        }
                    }
                } else {
                    ksaSchedule.isPaid = false;
                    ksaSchedule.amount = ((totalAmount/100) * (plan.fw1__Installment_Percentage__c));    
                }    
            } else {
                ksaSchedule.isPaid = false;
                ksaSchedule.amount = ((totalAmount/100) * (plan.fw1__Installment_Percentage__c));    
            }
            schedules.add(ksaSchedule);
        }
        return schedules;
    }
    
    @AuraEnabled
    public static void processQuotePayment(Boolean isEdit, String webcode, String selectedInstallmentsJson, String eventPackageListJson, String registrationWrapperJson, Boolean doPayment, String registrationRecordType) {
        PaymentResponse res = new PaymentResponse();
        try {
            List<KSAPaymentSchedule> selectedInstallments = (List<KSAPaymentSchedule>)JSON.deserialize(selectedInstallmentsJson, List<KSAPaymentSchedule>.class);
            List<KSAQuote> quotePackages = (List<KSAQuote>)JSON.deserialize(eventPackageListJson, List<KSAQuote>.class);
            RegistrationWrapper regWrapper = (RegistrationWrapper)JSON.deserialize(registrationWrapperJson, RegistrationWrapper.class);
            if(doPayment)  {
                Contact POC = regWrapper.con;
                Quote__c ksaQuote = regWrapper.quote;
                res = KSA_PaymentCtrl.processPayment(ksaQuote.Paid_Amount__c,ksaQuote.Credit_Card_Number__c,
                                                                     ksaQuote.Exp_Month__c, ksaQuote.Exp_Year__c,ksaQuote.CVV__c, POC.MailingStreet, 
                                                                     POC.MailingCity, POC.MailingState, 
                                                                     POC.MailingPostalCode, POC.MailingCountry, POC.Email,POC.FirstName,
                                                                     POC.LastName,webcode, null);
                
                if(res.IsSuccessful == true) {
                    createRecords(isEdit, webcode, selectedInstallments, quotePackages, regWrapper, res.payment, registrationRecordType);    
                } else {
                    throw new AuraHandledException(res.Message+ ' '+res.ErrorType+' '+ksaQuote.Paid_Amount__c+' '+ksaQuote.Credit_Card_Number__c+' '+ksaQuote.Exp_Month__c+' '+ksaQuote.Exp_Year__c+' '+ksaQuote.CVV__c);
                }
            }  else {
                createRecords(isEdit, webcode, selectedInstallments, quotePackages, regWrapper, null, registrationRecordType);
            }
        } catch(Exception e)  {
            if(!Test.isRunningTest()) {
                if(res.IsSuccessful == true) {
                    throw new AuraHandledException(e.getMessage()+' '+e.getLineNumber()+' '+e.getStackTraceString());
                } else {
                    throw new AuraHandledException(e.getMessage()+' '+e.getLineNumber()+' '+e.getStackTraceString());
                }
            }   
        }
    }
    
    @AuraEnabled 
    public static void createRecords(Boolean isEdit, String webcode, List<KSAPaymentSchedule> selectedInstallments, List<KSAQuote> quotePackages, RegistrationWrapper regWrapper, fw1__Payment__c payment, String registrationRecordType) {
        List<Registrations__c> regs = new List<Registrations__c>();
        List<fw1__Invoice_Line__c> lineItems = new List<fw1__Invoice_Line__c>();
        List<Registration_Line_Item__c> lineItemstoInsert = new List<Registration_Line_Item__c>();
        Opportunity opp = [Select Id, AccountId, KSA_WebCode__c, Payment_Plan__c, account.Name, sportName__c  from Opportunity where KSA_Webcode__c=:webcode LIMIT 1];
        
        Contact POC = regWrapper.con;
        POC.UserName__c = POC.Email;
        POC.Password__c = System.today().year()+POC.LastName.substring(0,2)+'@'+System.today().day();
        
        POC.AccountId = opp.AccountId;
        upsert POC;
        
        Quote__c ksaQuote = regWrapper.quote;
        ksaQuote.Opportunity__c = opp.Id;
        kSAQuote.Contact__c = POC.Id;
        if(registrationRecordType != null && registrationRecordType != '') {
            ksaQuote.Quote_By__c = registrationRecordType;
        }
        
        if(opp.Payment_Plan__c != null) {
            ksaQuote.Payment_Plan__c = opp.Payment_Plan__c;
        }
        upsert ksaQuote;
        
        Registrations__c athleteRecord = regWrapper.reg;
        if(regWrapper.reg.Last_Name__c != null) {
            athleteRecord.Quote__c = ksaQuote.id;
            athleteRecord.Opportunity__c = opp.Id;
            athleteRecord.Contact__c = POC.id;
            athleteRecord.School_Name__c = opp.account.Name;
            athleteRecord.Sport__c = opp.sportName__c;
            if(registrationRecordType != null) {
                athleteRecord.RecordTypeId = Schema.SObjectType.Registrations__c.getRecordTypeInfosByName().get(registrationRecordType).getRecordTypeId();    
            }  
        }
        List<fw1__Invoice_Line__c> invoiceLines = new List<fw1__Invoice_Line__c>();
        for(KSAQuote quotePck : quotePackages) {
            if(quotePck.rooms != null) {
                for(Room r : quotePck.rooms) {
                    if(r.persons != null) {
                        if(r.persons.size () > 0) {
                            for(Registrations__c reg : r.persons) {
                                Integer index = 1;
                                if(reg.Last_Name__c != null) {
                                    reg.Quote__c =  ksaQuote.Id;
                                    reg.Opportunity__c = opp.Id;
                                    if(index == 1) {
                                        reg.RecordTypeId = Schema.SObjectType.Registrations__c.getRecordTypeInfosByName().get(registrationRecordType).getRecordTypeId();    
                                    } else {
                                        reg.RecordTypeId = Schema.SObjectType.Registrations__c.getRecordTypeInfosByName().get('TAG').getRecordTypeId();
                                    }
                                    
                                    reg.Contact__c = POC.Id;
                                    reg.Account__c = opp.AccountId;
                                    reg.Webcode__c = opp.KSA_Webcode__c;
                                    reg.School_Name__c = athleteRecord.Sport__c;
                                    reg.Sport__c = athleteRecord.Sport__c;
                                    regs.add(reg);
                                }
                            }
                        }
                    }
                }    
            }

            Map<Id,List<Room>> selectedPckRooms = new Map<Id,List<Room>>();
            selectedPckRooms.put(quotePck.packageId, quotePck.rooms);

            if(quotePck.regLineItem != null) {
                if(quotePck.isSelected) {
                    quotePck.regLineItem.Event_Group_Product__c = quotePck.packageId;
                    quotePck.regLineItem.Quantity__c = quotePck.packageQuantity;
                    quotePck.regLineItem.Quote__c = ksaQuote.Id;
                    lineItemstoInsert.add(quotePck.regLineItem);
                    fw1__Invoice_Line__c invoiceLine = new fw1__Invoice_Line__c();
                    //invoiceLine.fw1__Invoice__c = invoice.Id;
                    invoiceLine.Name = quotePck.pckg.Product__r.Name;
                    invoiceLine.fw1__Product2__c = quotePck.pckg.Product__c;
                    invoiceLine.fw1__Quantity__c = quotePck.packageQuantity;
                    
                    if(quotePck.isAddon) {
                        invoiceLine.fw1__Unit_Price__c = quotePck.pckg.Sales_Price__c;  
                        quotePck.regLineItem.Amount__c = quotePck.pckg.Sales_Price__c;  
                        quotePck.regLineItem.RecordTypeId = Schema.SObjectType.Registration_Line_Item__c.getRecordTypeInfosByName().get('Product Add On').getRecordTypeId();
                    } else {
                        quotePck.regLineItem.RecordTypeId = Schema.SObjectType.Registration_Line_Item__c.getRecordTypeInfosByName().get('Product Package').getRecordTypeId();
                        if(registrationRecordType == 'Athlete') {
                            invoiceLine.fw1__Unit_Price__c = quotePck.pckg.Sales_Price__c;  
                            quotePck.regLineItem.Amount__c = quotePck.pckg.Sales_Price__c;  
                        }  else {
                           invoiceLine.fw1__Unit_Price__c = quotePck.pckg.Sales_Price__c * quotePck.pckg.Room_Size__c;     
                            quotePck.regLineItem.Amount__c = quotePck.pckg.Sales_Price__c *  quotePck.pckg.Room_Size__c;  
                        }
                    }
                    invoiceLines.add(invoiceLine);
                }
            }
        }
        
        List<Rooms__c> lstRoomNo = [Select id, Room_No__c from Rooms__c where Opportunity__c in (select id from opportunity where KSA_Webcode__c = :webcode) order by createddate desc limit 1];

        if(!lineItemstoInsert.isEmpty()) {
            Integer roomNumber = 0;
            if(!lstRoomNo.isEmpty()) {
                String strRoomNumber = (lstRoomNo.get(0).Room_No__c).split(' ')[1];
                roomNumber = Integer.valueOf(strRoomNumber);
            }
			
            Set<Id> setEGP = new Set<Id>();
            for(Registration_Line_Item__c regLine : lineItemstoInsert) {
                setEGP.add(regLine.Event_Group_Product__c);
            }
            
            Map<Id, Event_Group_Package__c> mapIdEGP = new Map<Id, Event_Group_Package__c> ([select id, Room_Size__c, product__r.Room_Type__c, Team_Opportunity__c
                                                                                             from Event_Group_Package__c where id in :setEGP and recordType.Name = 'Product Package']);
            system.debug('mapIdEGP '+mapIdEGP);
            List<Rooms__c> lstRooms = new List<Rooms__c>();
            for(Registration_Line_Item__c regLine : lineItemstoInsert) {
                system.debug('3 ' +mapIdEGP.get(regLine.Event_Group_Product__c));
                if(mapIdEGP.get(regLine.Event_Group_Product__c) != null) {
                    for(integer i = 0; i < regLine.Quantity__c; i++) {
                        roomNumber++;
                        Rooms__c regRoom = new Rooms__c();
                        regRoom.Room_No__c = 'Room '+(roomNumber);
                        regRoom.KSA_Quote__c = regLine.Quote__c;
                        regRoom.Opportunity__c = mapIdEGP.get(regLine.Event_Group_Product__c).Team_Opportunity__c;
                        regRoom.Type__c = mapIdEGP.get(regLine.Event_Group_Product__c).product__r.Room_Type__c;
                        lstRooms.add(regRoom);
                    }
                }
            }
            
            if(!lstRooms.isEmpty()) {
                insert lstRooms;
            }
        }
        
        If(Test.isRunningTest() == false) {
            upsert regs;
            upsert lineItemstoInsert;
        }

        if(payment != null) {
            createInvoice(opp, ksaQuote, POC, payment, invoiceLines, selectedInstallments, isEdit);
        }
    }

    @AuraEnabled
    public static UserInfo hasUserDetails(String email, String webcode) {
        List<Quote__c> lstQuote = [Select id from Quote__c where Opportunity__r.KSA_Webcode__c = :webcode and contact__r.email =:email limit 1];

        if(lstQuote.isEmpty()) {
            UserInfo info = new UserInfo();
            List<Contact> contacts = [Select Id,FirstName,LastName,Email,Phone,MailingStreet,MailingCity,MobilePhone,
                                      MailingState,MailingCountry,MailingPostalCode 
                                      from Contact where Email=:email];
            if(contacts.size() > 0) {
                info.con = contacts[0];
                info.isExistingUser = true;
            } else {
                info.isExistingUser = false;
            }
            return info;
        } else {
            return null;
        }
    }
    
    public static List<Registrations__c> getEventQuoteRegistrations(String eventPacakgeId,String quoteId) {
        List<Registrations__c> quoteRegLines = [Select Id, Name, Room_No__c, First_Name__c, Last_Name__c, Middle_Name__c,
                                                Gender__c, Birth_Date__c, Shirt_Size_25__c FROM Registrations__c  where Quote__c = :quoteId
                                                AND Event_Group_Package__c = :eventPacakgeId];
        return quoteRegLines;
    }
    
    public static void createInvoice(Opportunity opp,Quote__c ksaQuote, Contact POC, fw1__Payment__c payment, List<fw1__Invoice_Line__c> invoiceLines, List<KSAPaymentSchedule> selectedInstallments, Boolean isEdit) {
        fw1__Invoice__c invoice;
        if(isEdit == false) {
            invoice = new fw1__Invoice__c();    
            invoice.fw1__Account__c = opp.AccountId;
            invoice.Quote__c = ksaQuote.Id;
            invoice.fw1__Contact__c = POC.Id;
            invoice.fw1__Opportunity__c = opp.Id;  
            if(opp.Payment_Plan__c != null) {
                invoice.fw1__Payment_Plan__c = opp.Payment_Plan__c;    
            }
            
            insert invoice; 
            for(fw1__Invoice_Line__c invoiceLine : invoiceLines) {
                invoiceLine.fw1__Invoice__c = invoice.Id;
            }
            insert invoiceLines;
        } else {
            List<fw1__Invoice__c> invoices = [Select Id, fw1__Total_Paid_Amount__c from fw1__Invoice__c where Quote__c = :ksaQuote.Id Limit 1];
            if(invoices.size() > 0) {
                invoice = invoices[0]; 
            } else {
                invoice = new fw1__Invoice__c();
                invoice.fw1__Account__c = opp.AccountId;
                invoice.Quote__c = ksaQuote.Id;
                invoice.fw1__Contact__c = POC.Id;
                invoice.fw1__Opportunity__c = opp.Id;
                if(opp.Payment_Plan__c != null) {
                    invoice.fw1__Payment_Plan__c = opp.Payment_Plan__c;    
                }
                
                insert invoice;
                
                for(fw1__Invoice_Line__c invoiceLine : invoiceLines) {
                    invoiceLine.fw1__Invoice__c = invoice.Id;
                }
                insert invoiceLines;
            }
        }
        
        payment.Quote__c = ksaQuote.Id;
        payment.fw1__Account__c = opp.AccountId;
        payment.fw1__Opportunity__c = opp.Id;
        payment.fw1__Contact__c = POC.Id;
        payment.fw1__Invoice__c = invoice.Id;
        update payment;
        Task tsk = new Task();
        tsk.WhoId = POC.Id;
        tsk.OwnerId = Label.KSA_Payments_Queue_ID;
        tsk.Subject = 'Payment has been created.';
        tsk.ActivityDate = System.today().addDays(7);
        tsk.WhatId = payment.Id;
        tsk.IsReminderSet = true;
        insert tsk;  

        List<fw1__Installment__c> autoCreatedInstallments = [Select Id,fw1__Payment__c,Plan_Installment__c,
                                                             fw1__Total_Installment_Amount__c,fw1__Paid_Amount__c,
                                                             Plan_Installment__r.fw1__Installment_Number__c,fw1__Status__c
                                                             from fw1__Installment__c where  fw1__Invoice__c=:invoice.Id
                                                             Order By Plan_Installment__r.fw1__Installment_Number__c];

        for(fw1__Installment__c inst : autoCreatedInstallments) {
            if(inst.fw1__Payment__c == null) {
                for(KSAPaymentSchedule sch : selectedInstallments) {
                    if(sch.planId == inst.Plan_Installment__c)  {
                        inst.fw1__Payment__c = payment.Id;
                        if(inst.fw1__Paid_Amount__c == null) {
                            inst.fw1__Paid_Amount__c = sch.amount;    
                        } else {
                            inst.fw1__Paid_Amount__c = inst.fw1__Paid_Amount__c + sch.amount;
                        }
                    }
                }
            }
        }
        
        update autoCreatedInstallments;
    }
    
    public static  Map<Id, Registration_Line_Item__c> getEventLineItems(String quoteId) {
        Map<Id, Registration_Line_Item__c> quoteRegLinesMap = new Map<Id, Registration_Line_Item__c>();
        
        List<Registration_Line_Item__c> quoteRegLines = [Select Id, Name, Event_Group_Product__c, Amount__c, Quantity__c,
                                                         Registration__c, Quote__c, To__c, From__c from Registration_Line_Item__c
                                                         where Quote__c = :quoteId];
        
        for(Registration_Line_Item__c reg : quoteRegLines) {
            if(reg.Event_Group_Product__c != null) {
                quoteRegLinesMap.put(reg.Event_Group_Product__c, reg);
            }
        }
        return quoteRegLinesMap;
    }
    
    public static  Map<Id,Registrations__c> getQuoteRegistrations(String quoteId) {
        List<Registrations__c> quoteRegLines = [Select Id,Name,Room_No__c,First_Name__c,Last_Name__c,Middle_Name__c,
                                                Gender__c,Birth_Date__c,Shirt_Size_25__c,Event_Group_Package__c
                                                FROM Registrations__c
                                                where Quote__c=:quoteId
                                                AND RecordType.Name='TAG'];
        Map<Id,Registrations__c> quoteRegMap = new Map<Id,Registrations__c>();
        
        for(Registrations__c reg:quoteRegLines)
        {
            if(reg.Event_Group_Package__c!=null)
            {
                quoteRegMap.put(reg.Event_Group_Package__c, reg);
            }
        }
        return quoteRegMap;
    }
    
    public class PickListWrapper {
        @AuraEnabled
        public String value;
        @AuraEnabled
        public String label;
    }
    
    public class UserInfo {
        @AuraEnabled
        public Boolean isExistingUser;
        @AuraEnabled
        public Contact con;
    }*/

}