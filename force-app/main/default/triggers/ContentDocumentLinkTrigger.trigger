trigger ContentDocumentLinkTrigger on ContentDocumentLink (after insert, before insert) {
    if(Trigger.isInsert && Trigger.isBefore) {
        for(ContentDocumentLink linkDoc : Trigger.new) {
            linkDoc.Visibility = 'AllUsers';
        }
    }
    
    if(Trigger.isInsert && Trigger.isAfter) {
        Set<Id> productIds = new Set<Id>();
        Map<Id,ContentDocumentLink> productDocuments = new Map<Id,ContentDocumentLink>();
        Map<Id,ContentDocumentLink> contentDocumentsLinkMap = new Map<Id,ContentDocumentLink>();
        for(ContentDocumentLink linkDoc : Trigger.new) {
            if(linkDoc.LinkedEntityId != null) {
                if(String.valueOf(linkDoc.LinkedEntityId).startsWith('01t')) {
                    productIds.add(linkDoc.LinkedEntityId);
                    productDocuments.put(linkDoc.LinkedEntityId, linkDoc);
                    contentDocumentsLinkMap.put(linkDoc.ContentDocumentId, linkDoc);
                }    
            }
        }
        
        List<ContentVersion> contentsVersions = [select Id,ContentDocumentId,Title from ContentVersion where ContentDocumentId IN : contentDocumentsLinkMap.keySet()];
        Map<Id,ContentVersion> productVersionMap = new Map<Id,ContentVersion>();
        for(ContentVersion productVersion:contentsVersions) {
            productVersionMap.put(productVersion.ContentDocumentId, productVersion);
        }
        
        
        List<Product2> products = [Select Id,Name,Image_ID__c from Product2 where Id IN :productIds];
        Map<Id,Product2> productsMap = new Map<Id,Product2>();
        for(Product2 prd : products) {
            productsMap.put(prd.Id,prd);
        }
        
        for(ContentDocumentLink linkDoc : Trigger.new) {
            if(linkDoc.LinkedEntityId != null){
                if(String.valueOf(linkDoc.LinkedEntityId).startsWith('01t')) {
                    if(productsMap.get(linkDoc.LinkedEntityId) != null) {
                        if(productVersionMap.get(linkDoc.ContentDocumentId).Title== productsMap.get(linkDoc.LinkedEntityId).Name) {
                            productsMap.get(linkDoc.LinkedEntityId).Image_ID__c = productVersionMap.get(linkDoc.ContentDocumentId).Id; 
                        }
                    }
                }
            }
        }
        
        if(productsMap.size() > 0) {
            update productsMap.values();            
        }
    }
}