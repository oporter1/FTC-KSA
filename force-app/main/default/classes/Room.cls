public class Room{
    @AuraEnabled
    public Integer packageQuantity{get;set;}
    @AuraEnabled
    public Integer roomNo{get;set;}
    @AuraEnabled
    public List<Registrations__c> persons{get;set;}
  
    public List<SelectOption> personsCount{get;set;}
    @AuraEnabled
    public Integer selectedpersonsCount{get;set;}
    @AuraEnabled
    public Event_Group_Package__c eventPackage{get;set;}
    
    
}