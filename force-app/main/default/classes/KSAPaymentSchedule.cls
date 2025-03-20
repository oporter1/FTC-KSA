public class KSAPaymentSchedule {
    
    @AuraEnabled
    public String planId;
    @AuraEnabled
    public Decimal order;
    @AuraEnabled
    public Decimal percent;
    @AuraEnabled
    public Decimal amount;
    @AuraEnabled 
    public Date scheduleDate;
    @AuraEnabled
    public Boolean isPaid;
    @AuraEnabled
    public Boolean isSelected;
}