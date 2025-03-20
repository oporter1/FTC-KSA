@isTest
public class ProcessPaymentCtrlTest {
    @isTest static void testprocessPayment() {
        Contact con = new Contact();
        con.Email = 'Test@asd.com';
        con.LastName = 'Test';
        insert con;
        ProcessPaymentCtrl.processPayment(1000,'4111111111111111','11','2021','000','Test','Test','Test','Test',
                                          'Test','Test@asd.com','Test','Test','Test','Test');
    }
}