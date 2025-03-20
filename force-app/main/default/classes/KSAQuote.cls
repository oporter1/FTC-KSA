public class KSAQuote{
    @AuraEnabled
    public Event_Group_Package__c pckg{get;set;}
    @AuraEnabled
    public String packageId{get;set;}
    @AuraEnabled
    public String packageName{get;set;}
    @AuraEnabled
    public Integer packageQuantity{get;set;}
    @AuraEnabled
    public Integer addOnSubTotal{get;set;}
    @AuraEnabled
    public List<Room> rooms{get;set;}
    
    @AuraEnabled
    public Boolean isAddon{get;set;}
    @AuraEnabled
    public Boolean isSelected{get;set;}
    //Add-on Properties
    @AuraEnabled
    public Date fromDate{get;set;}
    @AuraEnabled
    public Date toDate{get;set;}
    @AuraEnabled
    public Registration_Line_Item__c regLineItem{get;set;}
}