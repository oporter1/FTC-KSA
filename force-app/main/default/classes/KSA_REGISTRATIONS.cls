public class KSA_REGISTRATIONS {
    public Registrations__c reg{get;set;}
    public Boolean isRegistrationSuccess{get;set;}
    
    public KSA_REGISTRATIONS(ApexPages.StandardController controller) {
        reg = new Registrations__c();
    }
    
    public PageReference registerAthlete()
    {
        try{
            System.debug('in Save...');
            
            reg.RecordTypeId = Schema.SObjectType.Registrations__c.getRecordTypeInfosByName().get('Athlete').getRecordTypeId();
            insert reg;
            system.debug('reg'+reg);  
            isRegistrationSuccess = true;
            reg = new Registrations__c();
            return null;
        }
        catch(Exception e)
        {
            System.debug('expetion message...'+e.getMessage());
            isRegistrationSuccess = false;
            return null;
        }
        
    }
    
    public PageReference registerTag()
    {
        try{
            System.debug('in Save...');
            
            reg.RecordTypeId = Schema.SObjectType.Registrations__c.getRecordTypeInfosByName().get('TAG').getRecordTypeId();
            insert reg;
            system.debug('reg'+reg);  
            isRegistrationSuccess = true;
            reg = new Registrations__c();
            return null;
        }
        catch(Exception e)
        {
            System.debug('expetion message...'+e.getMessage());
            isRegistrationSuccess = false;
            return null;
        }
        
    }
}