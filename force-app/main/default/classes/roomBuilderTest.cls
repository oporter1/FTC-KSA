/* ─────────────────────────────────────────────────────────────────────────────────────────────────
 * TITLE:          roomBuilderTest apex
 * DESCRIPTION:    Pulls/creates the least amount of rooms for all the athletes for a given a webcode
 * @created        03/24/2025
 * @updated
 * @by             FTC       hey@freethinkersconsulting.com
 * ──────────────────────────────────────────────────────────────────────────────────────────────────
 * @notes:
 */

@isTest
private class roomBuilderTest {
  @TestSetup
  static void makeData() {
    Account acc = new Account(Name = 'Test Account');
    insert acc;
    // Create an account
    Opportunity parentOpp = new Opportunity(
      AccountId = acc.Id,
      Name = 'Parent Opp',
      StageName = 'Inquiry',
      CloseDate = Date.today()
    );
    insert parentOpp;
    // These opps should create (2, 4 sized rooms), (1, 2 sized room), (2, 3 sized rooms), 2, (2, 1 sized room)
    // Data creation
    List<String> studentNames = new List<String>{
      'Alice',
      'Bob',
      'Charlie',
      'David',
      'Eve',
      'Frank',
      'Grace',
      'Hannah',
      'Ivy',
      'Jack',
      'Kara',
      'Liam',
      'Mona'
    };
    List<Contact> contactList = new List<Contact>();
    for (Integer i = 0; i < studentNames.size(); i++) {
      Contact con = new Contact(LastName = studentNames[i], AccountId = acc.Id);
      contactList.add(con);
    }
    insert contactList;
    List<Decimal> roomNums = new List<Decimal>{
      0.25,
      0.25,
      0.25,
      0.25,
      0.25,
      0.5,
      0.5,
      1,
      0.33,
      0.3,
      0.3,
      0.3,
      1
    };

    Integer i = 0;
    List<Opportunity> opps = new List<Opportunity>();
    for (Decimal num : roomNums) {
      Opportunity opp = new Opportunity(
        Name = studentNames[i],
        School_Contact__c = contactList[i].Id,
        AccountId = acc.Id,
        Arrival_Date__c = Date.today(),
        KSASport_or_Performing_Art__c = 'Volleyball',
        StageName = 'Inquiry',
        CloseDate = Date.today(),
        Team_Opportunity__c = parentOpp.Id,
        Billing_Type__c = 'Individual Billing',
        RecordTypeId = '012f4000000aRkUAAU' // athlete record type
      );

      if (num == 0.25) {
        opp.Quad_Rooms__c = num;
      } else if (num >= 0.3 && num <= 0.34) {
        opp.Triple_Room__c = num;
      } else if (num == 0.5) {
        opp.Double_Room__c = num;
      } else if (num == 1) {
        opp.Single_Room__c = num;
      }
      opps.add(opp);
      i++;
    }
    insert opps;
  }

  @isTest
  static void testFirstRun() {
    // TO DO: implement unit test
    Opportunity parentOpp = [
      SELECT Id, KSA_Webcode__c
      FROM Opportunity
      WHERE RecordTypeId != '012f4000000aRkUAAU'
    ];
    roomBuilder.AthletesAndRooms resp = roomBuilder.getAthletesAndRooms(
      parentOpp.KSA_Webcode__c
    );
    List<Rooms__c> rooms = resp.rooms;
    System.assertEquals(7, rooms.size());
    List<Rooms__c> allRooms = [SELECT Id FROM Rooms__c];
    System.assertEquals(7, allRooms.size());
    Integer room4Cnt = 0;
    Integer room3Cnt = 0;
    Integer room2Cnt = 0;
    Integer room1Cnt = 0;
    for (Rooms__c room : rooms) {
      String roomType = room.Type__c;
      if (roomType == '4') {
        room4Cnt++;
      } else if (roomType == '3') {
        room3Cnt++;
      } else if (roomType == '2') {
        room2Cnt++;
      } else if (roomType == '1') {
        room1Cnt++;
      }
    }
    // These values come from the comment in the testSetup method
    System.assertEquals(2, room4Cnt);
    System.assertEquals(2, room3Cnt);
    System.assertEquals(1, room2Cnt);
    System.assertEquals(2, room1Cnt);
  }

  // Will delete one of the Quad preference opportunities and reduce our room cnt down to 1 for quad rooms
  @isTest
  static void testDeleteMemberAfterRoomsAreCreated() {
    // TO DO: implement unit test
    Opportunity parentOpp = [
      SELECT Id, KSA_Webcode__c
      FROM Opportunity
      WHERE RecordTypeId != '012f4000000aRkUAAU'
    ];
    roomBuilder.getAthletesAndRooms(parentOpp.KSA_Webcode__c);
    Opportunity deleteQuad = [SELECT Id FROM Opportunity WHERE Quad_Rooms__c = 0.25 LIMIT 1];
    delete deleteQuad;

    roomBuilder.AthletesAndRooms resp = roomBuilder.getAthletesAndRooms(
      parentOpp.KSA_Webcode__c
    );
    List<Rooms__c> rooms = resp.rooms;
    System.assertEquals(6, rooms.size());
    List<Rooms__c> allRooms = [SELECT Id FROM Rooms__c];
    System.assertEquals(6, allRooms.size());
    Integer room4Cnt = 0;
    Integer room3Cnt = 0;
    Integer room2Cnt = 0;
    Integer room1Cnt = 0;
    for (Rooms__c room : rooms) {
      String roomType = room.Type__c;
      if (roomType == '4') {
        room4Cnt++;
      } else if (roomType == '3') {
        room3Cnt++;
      } else if (roomType == '2') {
        room2Cnt++;
      } else if (roomType == '1') {
        room1Cnt++;
      }
    }
    // These values come from the comment in the testSetup method
    System.assertEquals(1, room4Cnt);
    System.assertEquals(2, room3Cnt);
    System.assertEquals(1, room2Cnt);
    System.assertEquals(2, room1Cnt);
  }


  // Add an extra opp for Doubles. Will require +1 Double room
  @isTest
  static void testNewMemberAfterFirstRun() {
    Opportunity parentOpp = [
      SELECT Id, KSA_Webcode__c
      FROM Opportunity
      WHERE RecordTypeId != '012f4000000aRkUAAU'
    ];
    roomBuilder.AthletesAndRooms resp = roomBuilder.getAthletesAndRooms(
      parentOpp.KSA_Webcode__c
    );

    Account acc = [SELECT Id FROM Account];
    Opportunity opp = new Opportunity(
      Double_Room__c = 0.5,
      Name = 'asdf',
      AccountId = acc.Id,
      Arrival_Date__c = Date.today(),
      KSASport_or_Performing_Art__c = 'Volleyball',
      StageName = 'Inquiry',
      CloseDate = Date.today(),
      Team_Opportunity__c = parentOpp.Id,
      Billing_Type__c = 'Individual Billing',
      RecordTypeId = '012f4000000aRkUAAU' // athlete record type
    );
    insert opp;

    resp = roomBuilder.getAthletesAndRooms(parentOpp.KSA_Webcode__c);
    List<Rooms__c> rooms = resp.rooms;
    System.assertEquals(8, rooms.size());
    List<Rooms__c> allRooms = [SELECT Id FROM Rooms__c];
    System.assertEquals(8, allRooms.size());
    Integer room4Cnt = 0;
    Integer room3Cnt = 0;
    Integer room2Cnt = 0;
    Integer room1Cnt = 0;
    for (Rooms__c room : rooms) {
      String roomType = room.Type__c;
      if (roomType == '4') {
        room4Cnt++;
      } else if (roomType == '3') {
        room3Cnt++;
      } else if (roomType == '2') {
        room2Cnt++;
      } else if (roomType == '1') {
        room1Cnt++;
      }
    }
    // These values come from the comment in the testSetup method + 1 more since we're adding another 2nd room athlete
    System.assertEquals(2, room4Cnt);
    System.assertEquals(2, room3Cnt);
    System.assertEquals(2, room2Cnt);       // 1 more double room
    System.assertEquals(2, room1Cnt);
  }

  @isTest
  static void testUpdate() {
    Opportunity opp = [SELECT Id, KSA_Webcode__c FROM Opportunity LIMIT 1];
    roomBuilder.updateAthletes(new List<Opportunity>{ opp });
  }

  // Todo - Update above tests to check that room numbering stays ordered and no duplicates are re-created
}
