@isTest
public class RoomTest {
    @isTest static void RoomTest() {
        
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
        system.debug('CT id: '+ct);
        fw1__Payment_Plan__c pyt = new fw1__Payment_Plan__c(fw1__Schedule__c='Daily',fw1__Installment_Fee__c=100);
        insert pyt;
       Opportunity opId = new Opportunity(Payment_Plan__c=pyt.Id,AccountId=testAccount.Id,Name = 'ETTest',StageName='Value Proposition',OwnerId=UserInfo.getUserId(),CloseDate = Date.newinstance(2022, 2, 17));
       insert opId;
    Product2 prod = new Product2(Name = 'Laptop X200',Family = 'Hardware',Description='HjhJHjsds sdss',Sales_Price__c=33.33,
                                    Room_Type__c='2');
    insert prod;
    Event_Group_Package__c eventGP  = new Event_Group_Package__c(Product__c=prod.Id,Team_Opportunity__c=opId.Id);
    insert eventGP;
        Test.startTest();
    Room rm = new Room();
    rm.eventPackage = eventGP;
    rm.packageQuantity = 2;
    rm.persons = new List<Registrations__c>();
    rm.personsCount = new List<SelectOption>();
    rm.roomNo = 2;
    rm.selectedpersonsCount=1;
        System.assertNotEquals(null, rm);
        Test.stopTest();
    }
}