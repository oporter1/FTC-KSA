public class KSA_WAIVERS 
{
    public KSA_Waivers__c wav{get;set;}
    public Boolean isWaiverSuccess{get;set;}
    
    public KSA_WAIVERS(ApexPages.StandardController controller) {
        wav = new KSA_Waivers__c();
    }
    
    public PageReference submitWaiver()
    {
        try{
            System.debug('in Save...');
            
            insert wav;
            system.debug('wav'+wav);  
            isWaiverSuccess = true;
            wav = new KSA_Waivers__c();
            return null;
        }
        catch(Exception e)
        {
            System.debug('expetion message...'+e.getMessage());
            isWaiverSuccess = false;
            return null;
        }
        
    }
    }