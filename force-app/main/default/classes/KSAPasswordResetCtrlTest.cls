@isTest
public class KSAPasswordResetCtrlTest {
    @isTest 
    static void testResetPassword() {
        Contact con = new Contact(lastName = 'Test Last Name', Password__c = 'Test');
        insert con;
        KSAPasswordResetCtrl.resetPassword(con.Id, 'Test', 'Test');
    }   
}