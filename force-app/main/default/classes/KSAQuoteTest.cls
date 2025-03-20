@istest
public class KSAQuoteTest {
    @isTest static void KSAQuoteTest() {
	Test.startTest();
    KSAQuote rm = new KSAQuote();
    rm.pckg = new Event_Group_Package__c();
    rm.packageId = '';
    rm.packageName = 'As';
    rm.packageQuantity = 2;
    rm.addOnSubTotal = 100;
    rm.isAddon = true;
    rm.isSelected = true;
    rm.rooms = new List<Room>();
    rm.toDate = Date.newinstance(2010, 2, 17);
    rm.regLineItem = new Registration_Line_Item__c();
    rm.fromDate = Date.newinstance(2010, 2, 17);
        
    System.assertNotEquals(null, rm);
    Test.stopTest();
    }
}