List<Opportunity> opportunities = [SELECT Id, Name, AccountId, Team_Opportunity__c, Account.Name, KSASport_or_Performing_Art__c, School_Contact__r.Name,
                       Departure_Date__c, Arrival_Date__c, Resort_Option__c,
                       KSA_Webcode__c, Coaches_Pin__c, CreatedDate, RecordType.Name, Billing_Type__c, Single_Room__c, Double_Room__c, Triple_Room__c, Quad_Rooms__c
                FROM Opportunity WHERE Team_Opportunity__r.KSA_Webcode__c = '25VB95880'];

for (Opportunity opp : opportunities) {
    opp.Coaches_Pin__c = 123;
}

update opportunities;

// These opps should create (2, 4 sized rooms), (1, 2 sized room), (2, 3 sized rooms), 2, (2, 1 sized room)
// Data creation
List<Decimal> roomNums = new List<Decimal>{0.25, 0.25, 0.25, 0.25, 0.25, 0.5, 0.5, 1, 0.33, 0.3, 0.3, 0.3, 1};
List<String> studentNames = new List<String>{'Alice', 'Bob', 'Charlie', 'David', 'Eve', 'Frank', 'Grace', 'Hannah', 'Ivy', 'Jack', 'Kara', 'Liam', 'Mona'};

Integer i = 0;
List<Opportunity> opps = new List<Opportunity>();
for (Decimal num : roomNums) {
    Opportunity opp = new Opportunity(
        Name = 'test re-add alice room 4',
        AccountId = '001O90000101KNZIA2',
        Arrival_Date__c = Date.today(),
        KSASport_or_Performing_Art__c = 'Volleyball',
        StageName = 'Inquiry',
        CloseDate = Date.today(),
        Team_Opportunity__c = '006U900000JL5BRIA1',
        Billing_Type__c = 'Individual Billing',
        RecordTypeId = '012f4000000aRkUAAU',
        Quad_Rooms__c = 0.25
    );
    insert opp;

    if (num == 0.25) {
        opp.Quad_Rooms__c = num;
    } else if (num >= 0.3 && num <= 0.34) {
        opp.Triple_Room__c = num;
    }  else if (num == 0.5) {
        opp.Double_Room__c = num;
    }  else if (num == 1) {
        opp.Single_Room__c = num;
    }
    opps.add(opp);
    i++;
}
insert opps;


// Test getting atheltes and rooms
String webcode = '25VB95880';
roomBuilder.AthletesAndRooms resp = roomBuilder.getAthletesAndRooms(webcode);

for (Opportunity athlete : resp.athletes) {
    System.debug('Athlete: ' + athlete);
}
for (Rooms__c room : resp.rooms) {
    System.debug('Room: ' + room);
}


// Delete rooms
List<Rooms__c> rooms = [SELECT Id FROM Rooms__c];
delete rooms;


delete (new Opportunity(Id = '006U900000JZqTpIAL'));


 006U900000JKmghIAD Room Builder Test - 0                          null    null           null           null           0.25          006U900000JL5BRIA1  
 006U900000JKmgiIAD Room Builder Test - 1                          null    null           null           null           0.25          006U900000JL5BRIA1  
 006U900000JKmgjIAD Room Builder Test - 2                          null    null           null           null           0.25          006U900000JL5BRIA1  
 006U900000JKmgkIAD Room Builder Test - 3                          null    null           null           null           0.25          006U900000JL5BRIA1  
 006U900000JKmglIAD Room Builder Test - 4                          null    null           null           null           0.25          006U900000JL5BRIA1  
 006U900000JKmgmIAD Room Builder Test - 5                          null    null           0.5            null           null          006U900000JL5BRIA1  
 006U900000JKmgnIAD Room Builder Test - 6                          null    null           0.5            null           null          006U900000JL5BRIA1  
 006U900000JKmgoIAD Room Builder Test - 7                          null    1              null           null           null          006U900000JL5BRIA1  
 006U900000JKmgpIAD Room Builder Test - 8                          null    null           null           0.33           null          006U900000JL5BRIA1  
 006U900000JKmgqIAD Room Builder Test - 9                          null    null           null           0.3            null          006U900000JL5BRIA1  
 006U900000JKmgrIAD Room Builder Test - 10                         null    null           null           0.3            null          006U900000JL5BRIA1  
 006U900000JKmgsIAD Room Builder Test - 11                         null    null           null           0.3            null          006U900000JL5BRIA1  
 006U900000JKmgtIAD Room Builder Test - 12                         null    1              null           null           null          006U900000JL5BRIA1  
 006U900000JL5BRIA1 Room Builder Test - 0                          null    null           null           null           null          null                



update (new Opportunity(Id = '006U900000JL5BRIA1', Coaches_Pin__c = 123 ));


// Query opportunities
List<Opportunity> oppsToUpdate = [SELECT Id, Name, School_Contact__r.Name, StageName FROM Opportunity];

// Update all opportunities to 'Booked' stage
for(Opportunity opp : oppsToUpdate) {
    opp.StageName = 'Booked';
}

// Perform the update
update oppsToUpdate;
System.debug('Updated ' + oppsToUpdate.size() + ' opportunities to Booked stage');