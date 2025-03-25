public with sharing class ZeroCopyContactTransactionsController {
    public class CustomException extends Exception {} 
    public static String cdp_token {get; set;}

    public static String getCDPToken() {
        C360AuthController cdpAuth = new C360AuthController('default');  
        cdp_token = cdpAuth.dc_token;
        return cdp_token;        
    }  

    @AuraEnabled
    public static String getContactTransactions(String recordId) {
        String queryCriteria = '\'' + recordId + '\'';
        String query = '{' + '"sql"' + ':' + '"SELECT Amount__c, ContactID__c, CreatedBy__c, CreatedDate__c, Description__c, Email__c, ' +
                            + 'Status__c, TransactionDate__c, TransactionID__c, TransactionType__c ' + 
                        'FROM Contact_Transactions__dlm ' +
                        'WHERE ContactID__c =  ' + queryCriteria +
            			'"}';
        System.debug(LoggingLevel.DEBUG, query);
        String result = getResults(query);
        return result;
    }

	private static String getResults(String query) {
        System.debug(LoggingLevel.DEBUG, '---> query ' + query);
		cdp_token = getCDPToken();
        System.debug(LoggingLevel.DEBUG, cdp_token);
        String result = '';
        Http h = new Http();
        HttpRequest req = new HttpRequest();
        req.setMethod('POST');
        req.setHeader('Content-Type', 'application/json;charset=UTF-8');
        req.setHeader('Authorization', 'Bearer ' + cdp_token);
        req.setBody(query);        
		req.setEndpoint('https://mnrw0zbyh0yt0mldmmytqzrxg0.c360a.salesforce.com/api/v2/query');
        HttpResponse res = h.send(req);
        System.debug(LoggingLevel.DEBUG, '>>> raw output ' + res.getBody());  
        System.debug(LoggingLevel.DEBUG, '>>> status code ' + res.getStatusCode());  
        if(res.getStatusCode() == 500) {
            System.debug(LoggingLevel.ERROR, '>>> error ' + res.getStatus());  
            throw new CustomException(res.getBody());
        }
        Boolean errorFlag = false; 
        try{
            String tempData1 = res.getBody().replaceAll('__c','');
            String tempData2 = tempData1.replaceAll('ssot__', 'cdp_');
            String tempData3 = tempData2.replaceAll('metadata', 'cdp_metadata');            
            result = tempData2;
        }catch(exception ex) {
            errorFlag = true;
            System.debug(LoggingLevel.ERROR, '---> Error ' + ex.getMessage());
        }
        return result;               
        
    }
}