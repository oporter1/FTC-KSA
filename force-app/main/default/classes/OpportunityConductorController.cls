public class OpportunityConductorController {
    private final static String urlFieldName = 'Conductor__c';
    private String partnerServerUrl;
  private ApexPages.StandardSetController controller;
    private List<String> opportunityIds = new List<Id>();
    
    public String conductorUrl {get; private set;}
    
    public OpportunityConductorController(ApexPages.StandardSetController controller) {
        this.controller = controller;
        
        for (Opportunity opportunity : (List<Opportunity>)controller.getSelected()){ 
            opportunityIds.add(opportunity.Id);
        }
        
        partnerServerUrl = 'https://'+ApexPages.currentPage().getHeaders().get('Host')+'/services/Soap/u/26.0/'+UserInfo.getOrganizationId();
    }
    
    public PageReference prepareConductorUrl() {
        conductorUrl = 'https://conductor.congamerge.com' +
            '?MOID=' + String.join(new List<String>(opportunityIds),',') +
      '&SessionId=' + UserInfo.getSessionID() +
      '&ServerUrl=' + partnerServerUrl +
      '&UrlFieldName=' + urlFieldName;
        
        return null;
    }
 
}