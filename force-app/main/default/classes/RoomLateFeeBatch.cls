global without sharing class RoomLateFeeBatch implements Database.Batchable<SObject>, Schedulable{

    global void execute(SchedulableContext  sc) {
        RoomLateFeeBatch lateFeeJob = new RoomLateFeeBatch();
        Database.executebatch(lateFeeJob,50);
    }
    
    public class ApexBatchJobException extends Exception {}   
    private String query;
    //private fw1__Payment_Center_Setting__c settings = new fw1__Payment_Center_Setting__c();
    Decimal numberOfDays = getNumberOfDays();
	private static final string roomRateProductFamily  = 'Room Rates';
    public static String QUERY_CONSTANT =  
        'SELECT Id,Invoice_Age__c,fw1__Balance_Due__c, ' +
        '(SELECT id, Name, fw1__Invoice__c, fw1__Quantity__c FROM fw1__Invoice_Lines__r WHERE fw1__Product2__r.Family = : roomRateProductFamily  AND fw1__Quantity__c > 0) ' +
        'FROM fw1__Invoice__c ' +
        'WHERE Invoice_Age__c =: numberOfDays ' +
        'AND fw1__Is_Overdue__c = true ' +
        'AND fw1__Do_not_Add_Late_Fee__c = false ' + 
        'AND fw1__Balance_Due__c > 0';

         
    global RoomLateFeeBatch() {   
        this(QUERY_CONSTANT);  
    }
    
    global RoomLateFeeBatch(String queryString) {
        query = queryString;
    }
    
    //Method required by the framework to start the job execution.
    global Database.QueryLocator start(Database.BatchableContext BC){

        Database.QueryLocator qLocator = null;
        try {
            qLocator = Database.getQueryLocator(query);
        } catch (Exception e) {
            throw e;
        } 
        return qLocator;
    }
 
    //Method required by the framework to process the records returned by the query locator created in the start method.
    global void execute(Database.BatchableContext BC, List<SObject> sObjects){
        System.debug('>>>>> sObjects: ' + sObjects);
         
        fw1__Payment_Center_Setting__c settings = [
            SELECT Id,Apply_Room_Late_Fee__c,fw1__Flat_Fee_Amount__c,Minimum_Balance_Due_for_Late_Fee__c
            FROM fw1__Payment_Center_Setting__c
            WHERE Name = 'Default Settings'
            LIMIT 1
        ];
       
		if( !sObjects.isEmpty() && settings != null && settings.Apply_Room_Late_Fee__c && settings.fw1__Flat_Fee_Amount__c != null ){
			 
            List<fw1__Additional_Charge__c> addChargeList = new List<fw1__Additional_Charge__c>();
            for (fw1__Invoice__c inv :  (List<fw1__Invoice__c>) sobjects) {
                decimal lineQty = 0;
                for ( fw1__Invoice_Line__c il : inv.fw1__Invoice_Lines__r) {
                    lineQty += il.fw1__Quantity__c;
                }

                if ( lineQty > 0 && inv.fw1__Balance_Due__c >= settings.Minimum_Balance_Due_for_Late_Fee__c ) {
                    addChargeList.add(createLateFee(inv.Id, lineQty * settings.fw1__Flat_Fee_Amount__c));
                }
            }

            if(!addChargeList.isEmpty()){
                Database.insert(addChargeList, false);
            }
		}

        
    }  

    public static fw1__Additional_Charge__c createLateFee(Id invoiceId, decimal amount) {
        //add late fee as additional charge
        fw1__Additional_Charge__c ac = new fw1__Additional_Charge__c();
        ac.Name = System.Label.Late_Fee;
        ac.fw1__Fixed_Amount__c = amount;
        ac.fw1__Invoice__c = invoiceId;

        return ac;
    }
    
    //Method required and invoked by the framework when a batch job is done.
    global void finish(Database.BatchableContext BC){}
    
    public static Decimal getNumberOfDays(){
        Decimal numberOfDays;  
        fw1__Payment_Center_Setting__c settings = new fw1__Payment_Center_Setting__c();
        settings = fw1.ControlHelper.getSettings();
        if(settings.fw1__Number_of_Days_Late__c != null){
            numberOfDays = settings.fw1__Number_of_Days_Late__c;
        }        
        return numberOfDays;
    }
}