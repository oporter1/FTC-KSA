public with sharing class roomBuilder {
  public roomBuilder() {
  }

  @AuraEnabled(cacheable=false)
  public static AthletesAndRooms getAthletesAndRooms(String webcode) {
    String teamOppId = [
      SELECT Id
      FROM Opportunity
      WHERE KSA_Webcode__c = :webcode
    ]
    .Id;

    List<Opportunity> athletes = [
      SELECT
        Id,
        Name,
        School_Contact__r.Name,
        Room__c,
        Single_Room__c,
        Double_Room__c,
        Triple_Room__c,
        Quad_Rooms__c,
        Team_Opportunity__c,
        KSA_Webcode__c,
        Coaches_Pin__c,
        RecordType.Name
      FROM Opportunity
      WHERE
        Team_Opportunity__c = :teamOppId
        AND Id != :teamOppId
        AND Billing_Type__c = 'Individual Billing'
        AND RecordType.Name = 'Athlete Opportunity'
    ];
    System.debug('athletes - ' + athletes.size());

    List<Rooms__c> rooms = [
      SELECT Id, Opportunity__c, Name, Room_No__c, Room_Number__c, Type__c, CreatedDate
      FROM Rooms__c
      WHERE Opportunity__c = :teamOppId
    ];

    // Initialize helper variables
    Map<String, List<RoomObj>> roomType2RoomsMap = new Map<String, List<RoomObj>>();
    Map<Id, RoomObj> roomObjMap = new Map<Id, RoomObj>();
    for (Rooms__c room : rooms) {
      // Converting '4' -> 'Quad' so the mapping works
      room.Type__c = roomTypeInteger2String(room.Type__c);
      String key = room.Type__c;
      if (!roomType2RoomsMap.containsKey(key)) {
        roomType2RoomsMap.put(key, new List<RoomObj>());
      }
      RoomObj newRoomObj = new RoomObj(room, roomType2Integer(room.Type__c));
      roomType2RoomsMap.get(key).add(newRoomObj);
      roomObjMap.put(room.Id, newRoomObj);
    }

    System.debug('roomType2RoomsMap - ' + roomType2RoomsMap);
    System.debug('roomObjMap - ' + roomObjMap);

    // Loop over athletes and update availability
    for (Opportunity athlete : athletes) {
      if (athlete.Room__c != null && roomObjMap.containsKey(athlete.Room__c)) {
        RoomObj roomObj = roomObjMap.get(athlete.Room__c);
        roomObj.spacesLeft--;
      }
    }

    for (Opportunity athlete : athletes) {
      // check if athelte has a room
      // if yes - do nothing
      if (athlete.Room__c != null) {
        continue;
      }
      // if no - add to pre-existing room if it exists. If it doesnt exist create room and add them to it
      // check pre-existing rooms
      Decimal roomTypeNum = athleteRoomNumberType(athlete);
      String roomType = oppRoomType2RoomPicklist(roomTypeNum);
      if (roomType == 'None') {
        System.debug(
          'error athlete opportunity doesnt have any room field set - ' +
          athlete.Id
        );
        continue;
      }

      System.debug(
        'Athlete loop - ' +
          athlete.Name +
          ' : ' +
          roomTypeNum +
          ' , ' +
          roomType
      );

      List<RoomObj> roomObjs = roomType2RoomsMap.get(roomType);

      System.debug('\t roomObjs: ' + roomObjs);
      // No rooms of that type yet. Create one
      if (roomObjs == null) {
        roomType2RoomsMap.put(roomType, new List<RoomObj>());
        Rooms__c newRoom = new Rooms__c(
          Type__c = roomType,
          Opportunity__c = athlete.Team_Opportunity__c
        );
        RoomObj newRoomObj = new RoomObj(
          newRoom,
          roomType2Integer(roomType) - 1
        );
        roomType2RoomsMap.get(roomType).add(newRoomObj);
        continue;
      }

      // check availbility of rooms
      Boolean didAdd = false;
      for (RoomObj roomObj : roomObjs) {
        if (roomObj.spacesLeft > 0) {
          // add them
          // athelte.Rooms__c =
          roomObj.spacesLeft--;
          didAdd = true;
          break;
        }
      }

      // No rooms had enough space. So we must create another room
      if (!didAdd) {
        Rooms__c newRoom = new Rooms__c(
          Type__c = roomType,
          Opportunity__c = athlete.Team_Opportunity__c
        );
        RoomObj newRoomObj = new RoomObj(
          newRoom,
          roomType2Integer(roomType) - 1
        );
        roomType2RoomsMap.get(roomType).add(newRoomObj);
        continue;
      }
    }

    List<Rooms__c> everyRoom = new List<Rooms__c>();
    List<Rooms__c> newRooms = new List<Rooms__c>();

    Decimal counter = 0;
    for (List<RoomObj> roomObjs : roomType2RoomsMap.values()) {
      for (RoomObj roomObj : roomObjs) {
        Rooms__c room = roomObj.room;
        room.Type__c = String.valueOf(roomType2Integer(room.Type__c));
        everyRoom.add(room);
        System.debug('Every room - ' + room);
        if (room.Id == null) {
          room.Room_Number__c = counter + 1;
          counter += 1;
          newRooms.add(room);
        }
      }
    }
    System.debug('NewRooms - ' + newRooms.size());
    insert newRooms;

    // Combine new rooms and old rooms together
    AthletesAndRooms aar = new AthletesAndRooms(athletes, everyRoom);
    return aar;
  }

  @AuraEnabled(cacheable=false)
  public static void updateAthletes(List<Opportunity> athletes) {
    try {
      update athletes;
    } catch (Exception e) {
      throw new AuraHandledException(e.getMessage());
    }
  }

  // Helper methods
  public static Decimal athleteRoomNumberType(Opportunity athlete) {
    if (athlete.Single_Room__c != null) {
      return athlete.Single_Room__c;
    } else if (athlete.Double_Room__c != null) {
      return athlete.Double_Room__c;
    } else if (athlete.Triple_Room__c != null) {
      return athlete.Triple_Room__c;
    } else if (athlete.Quad_Rooms__c != null) {
      return athlete.Quad_Rooms__c;
    } else {
      return 0;
    }
  }

  public static String oppRoomType2RoomPicklist(Decimal roomTypeNum) {
    if (roomTypeNum == 0.25) {
      return 'Quad';
    } else if (roomTypeNum >= 0.3 && roomTypeNum <= 0.34) {
      // Avoids any annoying issues if they calcualte the Opp's room type for triples using 1/3 which represents 0.33333333 and possibly some random floating points at the end.
      return 'Triple';
    } else if (roomTypeNum == 0.5) {
      return 'Double';
    } else if (roomTypeNum == 1) {
      return 'Single';
    } else {
      return 'None';
    }
  }

  public static Integer roomType2Integer(String roomType) {
    if (roomType == 'Quad') {
      return 4;
    } else if (roomType == 'Triple') {
      return 3;
    } else if (roomType == 'Double') {
      return 2;
    } else if (roomType == 'Single') {
      return 1;
    } else {
      return 0;
    }
  }

  public static String roomTypeInteger2String(String roomType) {
    if (roomType == '4') {
      return 'Quad';
    } else if (roomType == '3') {
      return 'Triple';
    } else if (roomType == '2') {
      return 'Double';
    } else if (roomType == '1') {
      return 'Single';
    } else {
      return 'None';
    }
  }

  public class RoomObj {
    public Rooms__c room { get; set; }
    public Integer spacesLeft { get; set; }

    public RoomObj(Rooms__c room, Integer spacesLeft) {
      this.room = room;
      this.spacesLeft = spacesLeft;
    }
  }

  public class AthletesAndRooms {
    @AuraEnabled
    public List<Opportunity> athletes { get; set; }

    @AuraEnabled
    public List<Rooms__c> rooms { get; set; }

    public AthletesAndRooms(List<Opportunity> athletes, List<Rooms__c> rooms) {
      this.athletes = athletes;
      this.rooms = rooms;
    }
  }
}
