public without sharing class KSALoginCtrl {
    
    @AuraEnabled
    public static LoginWrapper userLogin(String username, String password) {
        
        LoginWrapper userWrapper =  new LoginWrapper();
        List<Contact> emps = [Select Id, Name, Email, Password__c, UserName__c, HasPasswordChange__c FROM Contact WHERE UserName__c=:username and Password__c =:password LIMIT 1];
        if(!emps.isEmpty()) {
            userWrapper.isValidDetails = true; 
            userWrapper.user = emps[0];
        } else {
            userWrapper.isValidDetails = false;
        }
        return userWrapper;
    }
    
    
    public class LoginWrapper{
        @AuraEnabled
        public Boolean isValidDetails{get;set;}
        @AuraEnabled
        public Object user{get;set;}
    }
    
    @AuraEnabled
    public static ForgotPasswordRes forgotPassword(String username) {
        ForgotPasswordRes res = new ForgotPasswordRes();
        List<Contact> con = [Select Id, Email, UserName__c, Password__c, HasPasswordChange__c FROM Contact WHERE UserName__c=:username  LIMIT 1];
        if(!con.isEmpty()) {
            try {
                Blob blobKey = crypto.generateAesKey(128);
                String key = EncodingUtil.convertToHex(blobKey);
                con[0].Password__c = key.substring(0,10);
                con[0].HasPasswordChange__c = false;
                update con; 
                res.isSuccess = True;
                res.email = con[0].Email;
                res.message = 'SUCCESS';
            } catch(Exception e) {
                res.isSuccess = false;
                res.email = e.getMessage();
                res.message = 'EXCEPTION';
            }
        } else {
            res.isSuccess = false;
            res.message = 'INVALID_USER';
        }
        
        return res;
    }
    
    public class ForgotPasswordRes{
        @AuraEnabled
        public Boolean isSuccess;
        @AuraEnabled
        public String email;
        @AuraEnabled
        public String message;
    }
}