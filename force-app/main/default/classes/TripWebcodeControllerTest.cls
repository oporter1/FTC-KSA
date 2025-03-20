@IsTest
private class TripWebcodeControllerTest {
    @TestSetup
    static void setupTestData() {
        // Create test Account
        Account testAccount = new Account(
            Name = 'Test School'
        );
        insert testAccount;
        
        // Create test Contact
        Contact testContact = new Contact(
            FirstName = 'Test',
            LastName = 'Contact',
            Email = 'test@example.com',
            Phone = '555-0123',
            AccountId = testAccount.Id
        );
        insert testContact;
        
        // Create test Opportunity with required fields for formula
        Opportunity testOpp = new Opportunity(
            Name = 'Test Trip',
            AccountId = testAccount.Id,
            StageName = 'Prospecting',
            CloseDate = Date.today().addDays(30),
            Arrival_Date__c = Date.newInstance(2024, 6, 1), // This will make X2_Digit_Year__c = '24'
            KSASport_or_Performing_Art__c = 'Football', // This will make Sport_Abbreviation__c = 'FB'
            Coaches_Pin__c = 1234,  // Integer field
            Departure_Date__c = Date.today().addDays(60),
            Predicted_Athletes__c = 10.0,
            Predicted_Coaches__c = 2.0,
            Predicted_Fans__c = 20.0,
            Resort_Option__c = 'Hard Rock Hotel',  // Use exact picklist value
            X2nd_Air_Schedule__c = 'Southwest',
            Inbound_Flight__c = '123',
            Air_Arrival_Date__c = Date.today().addDays(30),
            Air_Departure_Date__c = Date.today().addDays(35),
            Air_Booking_Notes__c = 'Test Notes'
        );
        insert testOpp;

        // Create Child Opportunities (Registered and Not Registered)
        List<Opportunity> childOpps = new List<Opportunity>();
        
        // Athlete Registered
        Opportunity athleteOpp = new Opportunity(
            Name = 'Test Athlete',
            AccountId = testAccount.Id,
            Team_Opportunity__c = testOpp.Id,
            School_Contact__c = testContact.Id,
            StageName = 'Booked',  // Correct stage name for registered opportunities
            CloseDate = Date.today(),
            RecordTypeId = '012f4000000aRkUAAU'
        );
        childOpps.add(athleteOpp);
        
        // Fan Not Registered
        Opportunity fanOpp = new Opportunity(
            Name = 'Test Fan',
            AccountId = testAccount.Id,
            Team_Opportunity__c = testOpp.Id,
            School_Contact__c = testContact.Id,
            StageName = 'Prospecting',
            CloseDate = Date.today(),
            RecordTypeId = '012f4000000aRkZAAU'
        );
        childOpps.add(fanOpp);
        insert childOpps;

        // Create Event Records
        List<Event__c> events = new List<Event__c>();
        Event__c event1 = new Event__c(
            GL_Opportunity__c = testOpp.Id,
            Event__C = 'Meal',
            Event_Type__c = 'Resort Buffet Breakfast',  // Use actual picklist value
            Theme_Park_Package__c = null,
            Date__c = Date.today().addDays(31),
            Quantity__c = 30,
            Location__c = 'Test Location',
            Event_Time__c = '10:00 AM',
            Departure_Time__c = '8:00 AM'
        );
        events.add(event1);
        
        Event__c event2 = new Event__c(
            GL_Opportunity__c = testOpp.Id,
            Event__C = 'Meal',
            Event_Type__c = 'Resort Buffet Breakfast',  // Use actual picklist value
            Date__c = null  // Testing null date sorting
        );
        events.add(event2);
        insert events;
    }
    
    private static String getTestWebcode() {
        Opportunity testOpp = [SELECT KSA_Webcode__c FROM Opportunity LIMIT 1];
        return testOpp.KSA_Webcode__c;
    }
    
    @IsTest
    static void testSuccessfulSearch() {
        String testWebcode = getTestWebcode();
        
        TripWebcodeController controller = new TripWebcodeController();
        controller.webcode = testWebcode;
        controller.pin = 1234;
        
        Test.startTest();
        PageReference result = controller.searchWebcode();
        Test.stopTest();
        
        System.assertNotEquals(null, result, 'Should return a page reference');
        System.assertEquals(null, controller.errorMessage, 'Should not have error message');
        System.assert(result.getUrl().containsIgnoreCase('TripDetails'), 'Should redirect to TripDetails page');
        System.assert(result.getParameters().containsKey('webcode'), 'URL should contain webcode parameter');
        System.assert(result.getParameters().containsKey('pin'), 'URL should contain pin parameter');
    }
    
    @IsTest
    static void testInvalidWebcode() {
        TripWebcodeController controller = new TripWebcodeController();
        controller.webcode = 'INVALID';
        controller.pin = 1234;
        
        Test.startTest();
        PageReference result = controller.searchWebcode();
        Test.stopTest();
        
        System.assertEquals(null, result, 'Should not redirect');
        System.assertEquals('Please Try Again', controller.errorMessage, 'Should show error message');
    }
    
    @IsTest
    static void testInvalidPin() {
        String testWebcode = getTestWebcode();
        
        TripWebcodeController controller = new TripWebcodeController();
        controller.webcode = testWebcode;
        controller.pin = 9999;
        
        Test.startTest();
        PageReference result = controller.searchWebcode();
        Test.stopTest();
        
        System.assertEquals(null, result, 'Should not redirect');
        System.assertEquals('Please Try Again', controller.errorMessage, 'Should show error message');
    }
    
    @IsTest
    static void testBlankInputs() {
        TripWebcodeController controller = new TripWebcodeController();
        
        Test.startTest();
        PageReference result = controller.searchWebcode();
        Test.stopTest();
        
        System.assertEquals(null, result, 'Should not redirect');
        System.assertEquals('Please Try Again', controller.errorMessage, 'Should show error message');
    }
    
    @IsTest
    static void testTripDetailsPageLoad() {
        String testWebcode = getTestWebcode();
        
        PageReference pageRef = Page.TripDetails;
        pageRef.getParameters().put('webcode', testWebcode);
        pageRef.getParameters().put('pin', '1234');
        Test.setCurrentPage(pageRef);
        
        // Mock invoice data
        TripWebcodeController.isTestMode = true;
        TripWebcodeController.testPaidAmount = 500;
        
        Test.startTest();
        TripWebcodeController controller = new TripWebcodeController();
        controller.loadTripDetails();
        Test.stopTest();
        
        // Verify trip details
        System.assertNotEquals(null, controller.foundTrip, 'Should find the trip');
        System.assertEquals('Test School', controller.foundTrip.Account.Name, 'Should load account name');
        
        // Verify registrations
        System.assertEquals(1, controller.registeredList.size(), 'Should have one registered person');
        System.assertEquals(1, controller.notRegisteredList.size(), 'Should have one not registered person');
        
        // Verify events
        System.assertEquals(2, controller.eventList.size(), 'Should have two events');
        
        // Verify payment calculations
        System.assertEquals(1000, controller.totalAmount, 'Total amount should be 1000');
        System.assertEquals(500, controller.totalPaid, 'Total paid should be 500');
        
        // Verify registration wrapper
        TripWebcodeController.RegistrationWrapper wrapper = controller.registeredList[0];
        System.assertEquals('Athlete', wrapper.travelerType, 'Should be an athlete registration');
        System.assertEquals(500, wrapper.invoice.fw1__Total_Paid_Amount__c, 'Should have correct payment amount');
    }
    
    @IsTest
    static void testTripDetailsUnauthorizedAccess() {
        PageReference pageRef = Page.TripDetails;
        pageRef.getParameters().put('webcode', 'INVALID');
        pageRef.getParameters().put('pin', 'WRONG');
        Test.setCurrentPage(pageRef);
        
        Test.startTest();
        TripWebcodeController controller = new TripWebcodeController();
        Test.stopTest();
        
        System.assertEquals(null, controller.foundTrip, 'Should not find any trip');
    }
    
    @IsTest
    static void testTripDetailsNoParameters() {
        PageReference pageRef = Page.TripDetails;
        Test.setCurrentPage(pageRef);
        
        Test.startTest();
        TripWebcodeController controller = new TripWebcodeController();
        Test.stopTest();
        
        System.assertEquals(null, controller.foundTrip, 'Should not find any trip');
    }
}