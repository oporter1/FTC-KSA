@isTest
public class KSA_REGISTRATIONS_Test {
    static  testMethod void testRegistrations()
    {
        Registrations__c reg = new Registrations__c();  
        KSA_REGISTRATIONS rregObj = new KSA_REGISTRATIONS(new ApexPages.StandardController( reg ) );
        rregObj.registerAthlete();
        rregObj.registerTag();
        
    }
}