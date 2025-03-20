trigger UpdateDummyQuote on Registrations__c (before insert) {
    
   /* for(Registrations__c reg:Trigger.new)
    {
        Id profileId= userinfo.getProfileId();
        String profileName=[Select Id,Name from Profile where Id=:profileId].Name;
        if(profileName == 'Application Profile' || profileName  =='AthleteRegistration Profile' || profileName =='Tag-A-LongRegistration Profile' )
        {
            reg.Quote__c = Label.KSA_Dummy_Quote;
        }
        
    }*/
    
}