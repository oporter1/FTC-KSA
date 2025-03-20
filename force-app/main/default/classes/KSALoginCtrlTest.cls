@isTest
public class KSALoginCtrlTest {
    @isTest static void loadKSAQuotesCtrlTest() {
        Account testAccount = new Account();
        testAccount.Name = 'TestAccount';
        insert testAccount;

		Contact ct = new Contact();
		ct.FirstName = 'FName123';
		ct.LastName = 'LName123';
		ct.Email = 'fff1223@test.com';
        ct.UserName__c = '121';
        ct.MailingStreet = 'test.com';
        ct.Password__c = 'BNG';
        ct.MailingState = 'New';
        ct.MailingPostalCode = '112121';
        ct.AccountId = testAccount.Id;
        insert ct;
        
    	Test.startTest();
        System.assertNotEquals(null, ct);
        KSALoginCtrl.userLogin('121','BNG');
        KSALoginCtrl.userLogin('121','');
        KSALoginCtrl.userLogin('','');
        
        KSALoginCtrl.LoginWrapper deWap = new KSALoginCtrl.LoginWrapper();
        deWap.isValidDetails = true;
		deWap.user = new User();
        
        KSALoginCtrl.ForgotPasswordRes paswrp = new KSALoginCtrl.ForgotPasswordRes();
        paswrp.email = 'email@test.com';
       	paswrp.isSuccess = true;
        paswrp.message = 'Helio';
        
        KSALoginCtrl.forgotPassword('');
        KSALoginCtrl.forgotPassword('121');
        Test.stopTest();
    }
}