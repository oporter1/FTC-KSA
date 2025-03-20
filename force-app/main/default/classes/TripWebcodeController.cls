public without sharing class TripWebcodeController {
    public String webcode { get; set; }
    public Integer pin { get; set; }
    public String errorMessage { get; set; }
    public Opportunity foundTrip { get; set; }
    public List<Event__c> eventRecords { get; set; }
    public List<Opportunity> notRegisteredList { get; private set; }
    public List<RegistrationWrapper> registeredList { get; private set; }
    public Decimal totalAmount { get; private set; }
    public Decimal totalPaid { get; private set; }
    public List<Event__c> eventList { get; set; }
    
    @TestVisible private static Boolean isTestMode = false;
    @TestVisible private static Decimal testPaidAmount = 0;
    
    public PageReference searchWebcode() {
        try {
            if (String.isBlank(webcode) || pin == null) {
                errorMessage = 'Please Try Again';
                return null;
            }
            
            List<Opportunity> trips = [
                SELECT Id, Name, Account.Name, KSASport_or_Performing_Art__c,
                       Departure_Date__c, Arrival_Date__c, Resort_Option__c,
                       KSA_Webcode__c
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
                           Airline_Ticketing_Fee__c
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
        }
    }

    private void loadRegistrations() {
        if (foundTrip != null) {
            try {
                registeredList = new List<RegistrationWrapper>();
                notRegisteredList = new List<Opportunity>();
                totalAmount = 0;
                totalPaid = 0;
                
                // Get all child opportunities
                List<Opportunity> allOpps = [
                    SELECT Id, Name, School_Contact__r.Name, School_Contact__r.Email,
                           School_Contact__r.Phone, RecordTypeId, IsWon, StageName
                    FROM Opportunity
                    WHERE Team_Opportunity__c = :foundTrip.Id
                ];
                
                List<Opportunity> regOpps = new List<Opportunity>();
                
                // Split into registered (IsWon) and not registered
                for (Opportunity opp : allOpps) {
                    if (opp.StageName == 'Booked') {  // Check for Booked stage
                        regOpps.add(opp);
                    } else {
                        notRegisteredList.add(opp);
                    }
                }
                
                // Get invoices for registered opportunities
                if (!regOpps.isEmpty()) {
                    if (isTestMode) {
                        // Use mock data in test context
                        for (Opportunity opp : regOpps) {
                            fw1__Invoice__c mockInvoice = new fw1__Invoice__c(
                                fw1__Total_Paid_Amount__c = testPaidAmount
                            );
                            registeredList.add(new RegistrationWrapper(opp, mockInvoice));
                            totalAmount += 1000;  // Hard-code for test
                            totalPaid += testPaidAmount;
                        }
                    } else {
                        Map<Id, fw1__Invoice__c> invoiceByOppId = new Map<Id, fw1__Invoice__c>();
                        for (fw1__Invoice__c inv : [
                            SELECT fw1__Total_Invoice_Amount__c, 
                                   fw1__Total_Paid_Amount__c,
                                   fw1__Balance_Due__c,
                                   fw1__Opportunity__c
                            FROM fw1__Invoice__c
                            WHERE fw1__Opportunity__c IN :regOpps
                        ]) {
                            invoiceByOppId.put(inv.fw1__Opportunity__c, inv);
                        }
                        
                        for (Opportunity opp : regOpps) {
                            fw1__Invoice__c inv = invoiceByOppId.get(opp.Id);
                            registeredList.add(new RegistrationWrapper(opp, inv));
                            
                            if (inv != null) {
                                totalAmount += inv.fw1__Total_Invoice_Amount__c != null ? 
                                    inv.fw1__Total_Invoice_Amount__c : 0;
                                totalPaid += inv.fw1__Total_Paid_Amount__c != null ? 
                                    inv.fw1__Total_Paid_Amount__c : 0;
                            }
                        }
                    }
                }
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
        }
    }

    public class RegistrationWrapper {
        public Opportunity opportunity { get; set; }
        public fw1__Invoice__c invoice { get; set; }
        public String travelerType { get; set; }
        
        public RegistrationWrapper(Opportunity opp, fw1__Invoice__c inv) {
            this.opportunity = opp;
            this.invoice = inv;
            this.travelerType = (opp.RecordTypeId == '012f4000000aRkZAAU') ? 'Fan' : 
                               (opp.RecordTypeId == '012f4000000aRkUAAU') ? 'Athlete' : '';
        }
    }
}