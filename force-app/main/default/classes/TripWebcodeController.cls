public without sharing class TripWebcodeController {
    public String webcode { get; set; }
    public Integer pin { get; set; }
    public String errorMessage { get; set; }
    public Opportunity foundTrip { get; set; }
    public List<Event__c> eventRecords { get; set; }
    public List<Opportunity> notRegisteredList { get; private set; }
    public List<RegistrationWrapper> registeredList { get; private set; }
    public List<RegistrationWrapper> allFansList { get; private set; }
    public Decimal totalAmount { get; private set; }
    public Decimal totalPaid { get; private set; }
    public List<Event__c> eventList { get; set; }
    
    // Constructor to initialize lists
    public TripWebcodeController() {
        eventRecords = new List<Event__c>();
        notRegisteredList = new List<Opportunity>();
        registeredList = new List<RegistrationWrapper>();
        allFansList = new List<RegistrationWrapper>();
        eventList = new List<Event__c>();
        totalAmount = 0;
        totalPaid = 0;
    }
    
    public PageReference searchWebcode() {
        try {
            if (String.isBlank(webcode) || pin == null) {
                errorMessage = 'Please Try Again';
                return null;
            }
            
            List<Opportunity> trips = [
                SELECT Id, Name, Account.Name, KSASport_or_Performing_Art__c,
                       Departure_Date__c, Arrival_Date__c, Resort_Option__c,
                       KSA_Webcode__c,
                       School_Contact__r.FirstName,
                       School_Contact__r.LastName,
                       School_Contact__r.Email,
                       School_Contact__r.Phone
                FROM Opportunity 
                WHERE KSA_Webcode__c = :webcode.trim()
                AND Coaches_Pin__c = :pin
                LIMIT 1
            ];
            
            if (!trips.isEmpty()) {
                PageReference pageRef = Page.TripDetails;
                pageRef.getParameters().put('webcode', webcode.trim());
                pageRef.getParameters().put('pin', String.valueOf(pin));
                pageRef.setRedirect(true);
                return pageRef;
            } else {
                errorMessage = 'Please Try Again';
                return null;
            }
        } catch (Exception e) {
            errorMessage = 'Please Try Again';
            return null;
        }
    }
    
    public void loadTripDetails() {
        try {
            String urlWebcode = ApexPages.currentPage().getParameters().get('webcode');
            String urlPin = ApexPages.currentPage().getParameters().get('pin');
            
            System.debug('URL Webcode: ' + urlWebcode);
            System.debug('URL Pin: ' + urlPin);
            
            if (String.isNotBlank(urlWebcode) && String.isNotBlank(urlPin)) {
                List<Opportunity> trips = [
                    SELECT Id, Name, Account.Name, KSASport_or_Performing_Art__c,
                           Departure_Date__c, Arrival_Date__c, Resort_Option__c,
                           KSA_Webcode__c, Predicted_Coaches__c,
                           Predicted_Fans__c, Predicted_Athletes__c,
                           X2nd_Air_Schedule__c,
                           Inbound_Flight__c, Air_Arrival_Date__c,
                           Inbound_Departure_Time__c, Inbound_Arrival_Time__c,
                           Air_Departure_Date__c, Outbound_Flight__c,
                           Outbound_Departure_Time__c, Outbound_Arrival_Time__c,
                           Air_Booking_Notes__c, Air_Contract_Signed__c,
                           Record_Locator__c, Deaprture_Airport_Code__c,
                           Arrival_Airport_Code__c, X2nd_Return_Airport_Code__c, Air_Inventory__c,
                           Seats_Sold__c, Estimated_Air_Rate__c,
                           Estimated_Air_Seats_Needed__c, Sold_Ticket_Price__c,
                           Airline_Ticketing_Fee__c, Billing_Type__c,
                           Baggage_Info__c, Airline_Manifest_Due__c
                    FROM Opportunity 
                    WHERE KSA_Webcode__c = :urlWebcode
                    AND Coaches_Pin__c = :Integer.valueOf(urlPin)
                    LIMIT 1
                ];
                
                System.debug('Found Trip: ' + (trips.isEmpty() ? 'No' : 'Yes'));
                if (!trips.isEmpty()) {
                    foundTrip = trips[0];
                    System.debug('Trip Webcode: ' + foundTrip.KSA_Webcode__c);
                    loadEvents();
                    loadRegistrations();
                    loadEventRecords();
                }
            }
        } catch (Exception e) {
            System.debug('Error in loadTripDetails: ' + e.getMessage());
            System.debug(e.getStackTraceString());
        }
    }
    
    private void loadEvents() {
        if (foundTrip != null) {
            eventRecords = [
                SELECT Event_Type__c, Theme_Park_Package__c,
                       Date__c, Quantity__c, Location__c,
                       Event_Time__c, Departure_Time__c
                FROM Event__c 
                WHERE GL_Opportunity__c = :foundTrip.Id
                ORDER BY Date__c ASC NULLS FIRST, Event_Time__c ASC NULLS FIRST
            ];
        } else {
            // Keep the initialized empty list
            eventRecords = new List<Event__c>();
        }
    }

    private void loadRegistrations() {
        if (foundTrip != null) {
            try {
                // Re-initialize lists
                registeredList = new List<RegistrationWrapper>();
                notRegisteredList = new List<Opportunity>();
                allFansList = new List<RegistrationWrapper>();
                totalAmount = 0;
                totalPaid = 0;
                
                System.debug('Found Trip ID: ' + foundTrip.Id);
                System.debug('Found Trip Webcode: ' + foundTrip.KSA_Webcode__c);
                
                // Get all child opportunities with record type information
                List<Opportunity> allOpps = [
                    SELECT Id, Name, 
                           School_Contact__r.Name, 
                           School_Contact__r.FirstName, 
                           School_Contact__r.LastName, 
                           School_Contact__r.Email, 
                           School_Contact__r.MobilePhone, 
                           School_Contact__r.Phone,
                           RecordTypeId, 
                           RecordType.Name, 
                           IsWon, 
                           StageName,
                           Count__c,
                           Other_Type__c
                    FROM Opportunity
                    WHERE (Team_Opportunity__c = :foundTrip.Id 
                           OR KSA_Webcode__c = :foundTrip.KSA_Webcode__c)
                    AND Id != :foundTrip.Id
                    ORDER BY RecordType.Name ASC, School_Contact__r.Name ASC
                ];
                
                System.debug('Total opportunities found: ' + allOpps.size());
                
                // Get all invoices for these opportunities
                Map<Id, fw1__Invoice__c> invoiceByOppId = new Map<Id, fw1__Invoice__c>();
                if (!allOpps.isEmpty()) {
                    for (fw1__Invoice__c inv : [
                        SELECT fw1__Total_Invoice_Amount__c, 
                               fw1__Total_Paid_Amount__c,
                               fw1__Balance_Due__c,
                               fw1__Opportunity__c,
                               CreatedDate
                        FROM fw1__Invoice__c
                        WHERE fw1__Opportunity__c IN :allOpps
                    ]) {
                        invoiceByOppId.put(inv.fw1__Opportunity__c, inv);
                    }
                }
                
                // Clear the lists first
                notRegisteredList.clear();
                registeredList.clear();
                
                // Use IsWon to determine registration status
                for (Opportunity opp : allOpps) {
                    if (opp.IsWon) {
                        fw1__Invoice__c inv = invoiceByOppId.get(opp.Id);
                        registeredList.add(new RegistrationWrapper(opp, inv));
                        if (inv != null) {
                            totalAmount += inv.fw1__Total_Invoice_Amount__c != null ? 
                                inv.fw1__Total_Invoice_Amount__c : 0;
                            totalPaid += inv.fw1__Total_Paid_Amount__c != null ? 
                                inv.fw1__Total_Paid_Amount__c : 0;
                        }
                    } else {
                        notRegisteredList.add(opp);
                    }
                }
                
                // Create allFansList with ALL Fan opportunities (including Tag Along Opportunity)
                System.debug('Total opportunities found: ' + allOpps.size());
                for (Opportunity opp : allOpps) {
                    System.debug('Opportunity: ' + opp.Name + ', RecordType: ' + opp.RecordType.Name);
                    if (opp.RecordType.Name == 'Fan' || opp.RecordType.Name == 'Tag_Along_Opportunity' || opp.RecordType.Name == 'Tag Along Opportunity') {
                        fw1__Invoice__c inv = invoiceByOppId.get(opp.Id);
                        Integer paxCount = getPaxCount(opp.Id);
                        allFansList.add(new RegistrationWrapper(opp, inv, paxCount));
                        System.debug('Added to allFansList: ' + opp.Name);
                    }
                }
                System.debug('Final allFansList size: ' + allFansList.size());
                
            } catch (Exception e) {
                System.debug('Error in loadRegistrations: ' + e.getMessage());
            }
        }
    }

    private void loadEventRecords() {
        if (foundTrip != null) {
            eventList = [
                SELECT Id, Name, Event_Type__c, Theme_Park_Package__c, Date__c, 
                       Quantity__c, Departure_Time__c, Event_Time__c, Location__c
                FROM Event__c 
                WHERE GL_Opportunity__c = :foundTrip.Id
                ORDER BY Date__c  NULLS FIRST, Event_Time__c NULLS FIRST
            ];
        } else {
            // Keep the initialized empty list
            eventList = new List<Event__c>();
        }
    }
    
    @TestVisible
    private Integer getPaxCount(Id opportunityId) {
        try {
            List<Registrations__c> registrations = [
                SELECT X1_First_Name__c, X1_Last_Name__c,
                       X2_First_Name__c, X2_Last_Name__c,
                       X3_First_Name__c, X3_Last_Name__c,
                       X4_First_Name__c, X4_Last_Name__c,
                       X5_First_Name__c, X5_Last_Name__c,
                       X6_First_Name__c, X6_Last_Name__c
                FROM Registrations__c 
                WHERE Opportunity__c = :opportunityId
                LIMIT 1
            ];
            
            if (registrations.isEmpty()) {
                return 0;
            }
            
            Registrations__c reg = registrations[0];
            Integer count = 0;
            
            // Count populated PAX names (both first and last name must be populated)
            if (String.isNotBlank(reg.X1_First_Name__c) && String.isNotBlank(reg.X1_Last_Name__c)) {
                count++;
            }
            if (String.isNotBlank(reg.X2_First_Name__c) && String.isNotBlank(reg.X2_Last_Name__c)) {
                count++;
            }
            if (String.isNotBlank(reg.X3_First_Name__c) && String.isNotBlank(reg.X3_Last_Name__c)) {
                count++;
            }
            if (String.isNotBlank(reg.X4_First_Name__c) && String.isNotBlank(reg.X4_Last_Name__c)) {
                count++;
            }
            if (String.isNotBlank(reg.X5_First_Name__c) && String.isNotBlank(reg.X5_Last_Name__c)) {
                count++;
            }
            if (String.isNotBlank(reg.X6_First_Name__c) && String.isNotBlank(reg.X6_Last_Name__c)) {
                count++;
            }
            
            return count;
        } catch (Exception e) {
            System.debug('Error getting PAX count for opportunity ' + opportunityId + ': ' + e.getMessage());
            return 0;
        }
    }

    public class RegistrationWrapper {
        public Opportunity opportunity { get; set; }
        public fw1__Invoice__c invoice { get; set; }
        public String travelerType { get; set; }
        public String bestPhoneNumber { get; set; }
        public Boolean isRegistered { get; set; }
        public Integer paxCount { get; set; }
        
        public RegistrationWrapper(Opportunity opp, fw1__Invoice__c inv) {
            this.opportunity = opp;
            this.invoice = inv;
            this.isRegistered = (inv != null);
            this.paxCount = 0;
            
                        // Use Record Type Name instead of hardcoded IDs
            if (opp.RecordType.Name == 'Fan' || opp.RecordType.Name == 'Tag_Along_Opportunity' || opp.RecordType.Name == 'Tag Along Opportunity') {
                this.travelerType = 'Fan';
            } else if (opp.RecordType.Name == 'Athlete_Opportunity' || opp.RecordType.Name == 'Athlete Opportunity') {
                this.travelerType = 'Athlete';
            } else if (opp.RecordType.Name == 'Other') {
                // For Other type - concatenate with Other_Type__c field
                if (String.isNotBlank(opp.Other_Type__c)) {
                    this.travelerType = 'Other (' + opp.Other_Type__c + ')';
                } else {
                    this.travelerType = 'Other';
                }
            } else {
                this.travelerType = opp.RecordType.Name;
            }
            this.bestPhoneNumber = String.isNotBlank(opp.School_Contact__r.MobilePhone) ? 
                                  opp.School_Contact__r.MobilePhone : 
                                  String.isNotBlank(opp.School_Contact__r.Phone) ? 
                                  opp.School_Contact__r.Phone : 'Not Available';
        }
        
        public RegistrationWrapper(Opportunity opp, fw1__Invoice__c inv, Integer paxCount) {
            this(opp, inv);
            this.paxCount = paxCount;
        }
    }
}
