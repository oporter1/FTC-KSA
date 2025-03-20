@isTest
private class KSA_TEST_CLASS {

 @isTest static void updateLead(){

        Lead myLead = new Lead();
        myLead.FirstName = 'Mickey';
        myLead.LastName = 'Mouse';
        myLead.Company = 'Disney';
        insert myLead;
    }

}