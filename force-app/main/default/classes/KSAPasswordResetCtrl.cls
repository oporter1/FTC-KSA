public without sharing class KSAPasswordResetCtrl {
    
    @AuraEnabled
    public static PasswordWrapper resetPassword(String userId, String password, String currentPassword) {
        
        PasswordWrapper pwdWrapper =  new PasswordWrapper();
        List<Contact> lstContact = [Select Id, Name, Email, Password__c, UserName__c, HasPasswordChange__c FROM Contact WHERE id=:userId and Password__c =:currentPassword LIMIT 1];
        if(!lstContact.isEmpty()) {
            Contact con = new Contact(id=lstContact.get(0).Id, Password__c = password, HasPasswordChange__c = true);
            update con;
            pwdWrapper.isValid = true;
            pwdWrapper.msg = 'Update Successfully !!!';
        } else {
            pwdWrapper.isValid = false;
            pwdWrapper.msg = 'Current Password is not valid.';
        }
        return pwdWrapper;
    }

    public class PasswordWrapper{
        @AuraEnabled
        public Boolean isValid{get;set;}
        @AuraEnabled
        public String msg{get;set;}
    }
}