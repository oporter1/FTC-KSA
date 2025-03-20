@isTest
public class KSA_REGISTRATIONSTest {
    @isTest static void loadKSAQuotesCtrlTest() {
        RecordType rt = [SELECT Id FROM RecordType WHERE sObjectType = 'Registrations__c' AND Name = 'ATHLETE'];
        RecordType rt1 = [SELECT Id FROM RecordType WHERE sObjectType = 'Registrations__c' AND Name = 'TAG'];
        Test.startTest();
        KSA_REGISTRATIONS regt = new KSA_REGISTRATIONS(new ApexPages.StandardController(new Registrations__c()));
        regt.registerAthlete();
        regt.registerTag();
        Test.stopTest();
    }
}