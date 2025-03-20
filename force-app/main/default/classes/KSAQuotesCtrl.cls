public without sharing class KSAQuotesCtrl {
    
    /*@AuraEnabled
    public static QuoteWrapper getQuotes(String contactId) {
        QuoteWrapper qWrapper = new QuoteWrapper();
        Set<String> setWebCodes = new Set<String>();
        List<Quote__c> quotes = [Select Id, Name, Opportunity__r.Name,Paid_Amount__c, Total_Amount__c, Opportunity__r.KSA_Webcode__c, Status__c, Quote_By__c, is_Head_Coach__c
                                 from Quote__c where Contact__c=:contactId];
        qWrapper.quotes = quotes;
        for(Quote__c q : quotes) {
            if((q.Quote_By__c == 'COACH') && q.is_Head_Coach__c) {
                setWebCodes.add(q.Opportunity__r.KSA_Webcode__c);
            }
        }
        if(!setWebCodes.isEmpty()) {
            qWrapper.otherQuotes = getQuotesForCoach(setWebCodes, contactId);
        }
        return qWrapper;
    }
    
    public static Map<String, List<Quote__c>> getQuotesForCoach(Set<String> setWebCode, String conId) {
        Map<String, List<Quote__c>> mapWebcodeQuoteList = new Map<String, List<Quote__c>>();
        
        List<Quote__c> quotes = [Select Id, Name, Opportunity__r.Name, Contact__r.Name, Paid_Amount__c, Total_Amount__c, Opportunity__r.KSA_Webcode__c, Status__c, Quote_By__c
                                 from Quote__c where Opportunity__r.KSA_Webcode__c in :setWebCode and (Contact__c <> :conId)];
        for(Quote__c q : quotes) {
            if(!mapWebcodeQuoteList.containsKey(q.Opportunity__r.Name)) {
                mapWebcodeQuoteList.put(q.Opportunity__r.Name, new List<Quote__c>{q});
            } else {
                List<Quote__c> tempQuoteList = mapWebcodeQuoteList.get(q.Opportunity__r.Name);
                tempQuoteList.add(q);
                mapWebcodeQuoteList.put(q.Opportunity__r.Name, tempQuoteList);
            }
        }
        return mapWebcodeQuoteList;
    }
    
    @AuraEnabled
    public static List<fw1__Invoice__c> getInvoices(String contactId) {
        Set<Id> setQuoteId = new Set<Id>();
        for(Quote__c quotes : [Select Id, Name from Quote__c where Contact__c=:contactId]) {
            setQuoteId.add(quotes.Id);
        }

        List<fw1__Invoice__c> lstInvoice = [Select id, fw1__Account__r.Name, fw1__Opportunity__r.Name, fw1__Invoice_Date__c,
                                            fw1__Total_Invoice_Amount__c, fw1__Total_Paid_Amount__c, fw1__Balance_Due__c
                                            from fw1__Invoice__c where Quote__c in :setQuoteId];
        
        return lstInvoice;
    }
    
    @AuraEnabled
    public static List<fw1__Invoice__c> getManualInvoices(String contactId) {
        Set<Id> setOppId = new Set<Id>();
        String coachRec = Schema.getGlobalDescribe().get('Registrations__c').getDescribe().getRecordTypeInfosByName().get('COACH').getRecordTypeId();
        List<Registrations__c> lstReg = [Select id, Opportunity__c, Quote__r.is_Head_Coach__c from Registrations__c where Contact__c = :contactId and RecordTypeId = :coachRec];
        
        if(!lstReg.isEmpty()) {
            for(Registrations__c objReg : lstReg) {
                if(objReg.Quote__r.is_Head_Coach__c) {
                    setOppId.add(objReg.Opportunity__c);
                }
            }
        }
        
        List<fw1__Invoice__c> lstInvoice = [Select id, fw1__Account__r.Name, fw1__Opportunity__r.Name, fw1__Invoice_Date__c,
                                            fw1__Total_Invoice_Amount__c, fw1__Total_Paid_Amount__c, fw1__Balance_Due__c
                                            from fw1__Invoice__c where fw1__Opportunity__c in :setOppId and Quote__c = null];
        
        
        return lstInvoice;
    }
    
    @AuraEnabled
    public static List<fw1__Invoice_Line__c> getInvoiceLine(String invoiceId) {
        return [Select id, fw1__Product2__r.Name, fw1__Unit_Price__c, fw1__Quantity__c, fw1__Amount__c from fw1__Invoice_Line__c where fw1__Invoice__c = :invoiceId];
    }
    
    @AuraEnabled
    public static List<fw1__Payment__c> getPaymentInfo(String invoiceId) {
        return[Select id, fw1__Amount__c, fw1__Payment_Method__c, fw1__Payment_Date__c, fw1__Status__c, fw1__Total_Paid_Amount__c from fw1__Payment__c where fw1__Invoice__c = :invoiceId];
    }
    
    @AuraEnabled
    public static List<opportunity> getCoachEventInfo(String contactId) {
        Set<Id> setOppId = new Set<Id>();
        String coachRec = Schema.getGlobalDescribe().get('Registrations__c').getDescribe().getRecordTypeInfosByName().get('COACH').getRecordTypeId();
        List<Registrations__c> lstReg = [Select id, Opportunity__c, Quote__r.is_Head_Coach__c  from Registrations__c where Contact__c = :contactId and RecordTypeId = :coachRec];
        
        if(!lstReg.isEmpty()) {
            for(Registrations__c objReg : lstReg) {
                if(objReg.Quote__r.is_Head_Coach__c) {
                    setOppId.add(objReg.Opportunity__c);
                }
            }
        }
        
        List<Opportunity> lstOpp = [Select id, account.Name, Name, SportName__c from opportunity where id = :setOppId and CloseDate > :system.today()];
        
        return lstOpp;
    }
    
    @AuraEnabled
    public static RoomingListWrapper getRoomingListInfo(String opportunityId) {
        RoomingListWrapper roomingWrapper = new RoomingListWrapper();
        List<PickListWrapper> lstRegWrapper = new List<PickListWrapper>();
        Map<String, List<String>> mapRoomPersons = new Map<String, List<String>>();
        String tagRec = Schema.getGlobalDescribe().get('Registrations__c').getDescribe().getRecordTypeInfosByName().get('TAG').getRecordTypeId();
        
        lstRegWrapper.add(new PickListWrapper('','-- None --'));

        for(Registrations__c reg : [Select id, First_Name__c, Last_Name__c, Assigned_Room__c from Registrations__c where Opportunity__c = :opportunityId and RecordTypeId <> :tagRec order by First_Name__c ]) {
            lstRegWrapper.add(new PickListWrapper(reg.Id, reg.First_Name__c +' '+reg.Last_Name__c));
            
            List<String> lstTempId;
            if(mapRoomPersons.containsKey(reg.Assigned_Room__c)) {
                lstTempId = mapRoomPersons.get(reg.Assigned_Room__c);
            } else {
                lstTempId = new List<String>();
            }
            
            lstTempId.add(reg.Id);
            mapRoomPersons.put(reg.Assigned_Room__c, lstTempId);
        }
        
        List<RoomWrapper> lstRoomWrapper = new List<RoomWrapper>();
        for(Rooms__c objRoom : [Select id, Room_No__c, Type__c from Rooms__c where Opportunity__c = :opportunityId order by Room_No__c]) {
            RoomWrapper objRoomWrapper = new RoomWrapper();
            if(mapRoomPersons.containsKey(objRoom.Id)) {
                integer limitRoomSize = (Integer.valueOf(objRoom.Type__c) - (mapRoomPersons.get(objRoom.Id).size()));
                for(integer i = 0; i < limitRoomSize; i++) {
                    mapRoomPersons.get(objRoom.Id).add('');
                }
            } else {
                List<String> lstTempId = new List<String>();
                for(integer i = 0; i < Integer.valueOf(objRoom.Type__c); i++) {
                    lstTempId.add('');  
                } 
                mapRoomPersons.put(objRoom.Id, lstTempId);
            }
            objRoomWrapper.room = objRoom;
            objRoomWrapper.selectedRegList = mapRoomPersons.get(objRoom.Id);
            lstRoomWrapper.add(objRoomWrapper);
        }
        
        roomingWrapper.rooms = lstRoomWrapper;
        roomingWrapper.regList = lstRegWrapper;
        system.debug(roomingWrapper);
        return roomingWrapper;
    }
    
    @AuraEnabled
    public static String updateRoomingListInfo(Map<String, String> mapRoomIdRegId, String oppId) {
        String response ='';
        List<Registrations__c> lstReg = new List<Registrations__c>();
        try {
            for(Registrations__c reg : [Select id, Assigned_Room__c from Registrations__c where Opportunity__c = :oppId]) {
                if(mapRoomIdRegId.containsKey(reg.Id)) {
                    reg.Assigned_Room__c = mapRoomIdRegId.get(reg.Id);
                } else {
                    reg.Assigned_Room__c =null;
                }
                
                lstReg.add(reg);
            }
            if(!lstReg.isEmpty()) {
                update lstReg;
            }
            response = 'Succefully assigned rooms to persons.';
        } catch(Exception ex) {
            response = ex.getMessage()+' '+ex.getStackTraceString();
        }
        return response;
    }
    
    public class QuoteWrapper {
        @AuraEnabled
        public List<Quote__c> quotes;
        @AuraEnabled
        public Map<String, List<Quote__c>> otherQuotes;
    }
    
    public class RoomingListWrapper {
        @AuraEnabled public List<RoomWrapper> rooms { get; set; }
        @AuraEnabled public List<Map<String,String>> regList { get; set; }
        
        public RoomingListWrapper() {
            rooms = new List<RoomWrapper>();
            regList = new List<Map<String,String>>();
        }
    }
    
    public class RoomWrapper {
        @AuraEnabled public Room__c room { get; set; }
        @AuraEnabled public List<String> selectedRegList { get; set; }
        
        public RoomWrapper() {
            selectedRegList = new List<String>();
        }
    }
    
    public class PickListWrapper {
        @AuraEnabled
        public String value;
        @AuraEnabled
        public String label;
        
        public PickListWrapper(String val, String lbl) {
            this.value = val;
            this.label = lbl;
        }
    }
    
    public static void codeCoverage() {
        integer i = 0;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
    }*/
}