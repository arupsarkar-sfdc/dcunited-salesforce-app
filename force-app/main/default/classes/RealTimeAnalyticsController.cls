public with sharing class RealTimeAnalyticsController {

    public class CustomException extends Exception {} 
    public static String cdp_token {get; set;}
    
    public static String getCDPToken() {
        C360AuthController cdpAuth = new C360AuthController('default');  
        cdp_token = cdpAuth.dc_token;
        return cdp_token;        
    }      

//https://mnrw0zbyh0yt0mldmmytqzrxg0.c360a.salesforce.com/api/v1/dataGraph/C360_Contact_RT?lookupKeys=[UnifiedLinkssotIndividualI1__dlm.SourceRecordId__c=0B803C90-8BCC-4821-AE1C-EBC1387B4EC2]

    @AuraEnabled(cacheable=true)
    public static String getDataGraphInfo(String sourceRecordId) {
        String endpoint = 'https://mnrw0zbyh0yt0mldmmytqzrxg0.c360a.salesforce.com/api/v1/dataGraph/C360_Contact_RT';
        String lookupKeys = 'UnifiedLinkssotIndividualI1__dlm.SourceRecordId__c=' + sourceRecordId;
        cdp_token = getCDPToken();
        Http http = new Http();
        HttpRequest request = new HttpRequest();
        request.setEndpoint(endpoint + '?lookupKeys=[' + lookupKeys + ']');
        request.setMethod('GET');
        request.setHeader('Content-Type', 'application/json;charset=UTF-8');
        request.setHeader('Authorization', 'Bearer ' + cdp_token);        
        HttpResponse jsonResponse = http.send(request);
        System.debug('jsonResponse before : ' + jsonResponse.getBody());

        String response = jsonResponse.getBody();
        // Remove "ssot__" and "__c" from the JSON string
        response = response.replace('ssot__', '').replace('__c', ''); 
        //Remove __dlm from the JSON string
        response = response.replace('__dlm', '');
        // Parse the modified JSON
        RealTimeDataGraphResponse jsonData = RealTimeDataGraphResponse.parse(response);   
        // print the parsed JSON
        System.debug('jsonData: ' + String.valueOf(jsonData));
        // Create a new structured response
        Map<String, Object> structuredResponse = new Map<String, Object>();        
        Map<String, Object> customerProfile = new Map<String, Object>();        
        try{
            // Access the parsed data
            if (jsonData.data != null && !jsonData.data.isEmpty()) {
                String jsonBlob = jsonData.data[0].json_blob;
                for (RealTimeDataGraphResponse.DataItem item : jsonData.data) {
                    RealTimeDataGraphResponse.JsonBlob parsedBlob = (RealTimeDataGraphResponse.JsonBlob) JSON.deserialize(jsonBlob, RealTimeDataGraphResponse.JsonBlob.class);
                    
                    // Now you can access the structured data
                    // Process the main JsonBlob data
                    System.debug('ID: ' + parsedBlob.Id);
                    System.debug('Created Date: ' + parsedBlob.CreatedDate);
                    System.debug('First Name: ' + parsedBlob.FirstName);
                    System.debug('Last Name: ' + parsedBlob.LastName);
                    System.debug('Is Anonymous: ' + parsedBlob.IsAnonymous);
                    System.debug('Unified String: ' + String.valueOf(parsedBlob.UnifiedLinkssotIndividualI1));
                    // Add customer information
                    customerProfile.put('customerId', parsedBlob.Id);
                    customerProfile.put('createdDate', parsedBlob.CreatedDate);
                    customerProfile.put('firstName', parsedBlob.FirstName);
                    customerProfile.put('lastName', parsedBlob.LastName);
                    customerProfile.put('isAnonymous', parsedBlob.IsAnonymous);
                    // customerProfile.put('unifiedId', String.valueOf(parsedBlob.UnifiedLinkssotIndividualI1));

                    // define a counter to keep track of the number of records
                    Integer recordCounter = 0;
                    if (parsedBlob.UnifiedLinkssotIndividualI1 != null) {
                        // Iterate through UnifiedLinks
                        for (RealTimeDataGraphResponse.UnifiedLink unifiedLink : parsedBlob.UnifiedLinkssotIndividualI1) {
                            System.debug('Source Record ID: ' + unifiedLink.SourceRecordId);
                            System.debug('Unified Record ID: ' + unifiedLink.UnifiedRecordId);
        
                            // Iterate through Individuals
                            if (unifiedLink.Individual != null) {
                                for (RealTimeDataGraphResponse.Individual individual : unifiedLink.Individual) {                    
                                    System.debug('Individual ID: ' + individual.Id);
                                    System.debug('Individual First Name: ' + individual.FirstName);
                                    System.debug('Individual Last Name: ' + individual.LastName);

                                    try{
                                        // Iterate through ContactPointEmails
                                        //Print the JSON data to the debug log for the ContactPointEmail
                                        System.debug('ContactPointEmail: ' + String.valueOf(individual.ContactPointEmail));
                                        if (individual.ContactPointEmail != null) {
                                            recordCounter++;
                                            System.debug('Record Counter: ' + recordCounter);
                                            List<Map<String, Object>> emailList = new List<Map<String, Object>>();                                            
                                            for (RealTimeDataGraphResponse.ContactPointEmail email : individual.ContactPointEmail) {
                                                if(email.EmailAddress != null){
                                                    System.debug('Email ID: ' + email.Id);
                                                    System.debug('Email Address: ' + email.EmailAddress);  
                                                    System.debug('Email Created Date: ' + email.CreatedDate);
                                                    Map<String, Object> emailData = new Map<String, Object>{
                                                        'emailId' => email.Id,
                                                        'emailAddress' => email.EmailAddress,
                                                        'createdDate' => email.CreatedDate
                                                    };
                                                    emailList.add(emailData);
                    
                                                }
                                            }
                                            customerProfile.put('emails', emailList);                                          
                                        } //end of if (individual.ContactPointEmail != null)                                        
                                    }catch(Exception e){
                                        throw new CustomException('ContactPointEmail : Error parsing JSON: ' + e.getMessage());
                                    }
                                        

                                    if (individual.ProductBrowseEngagement != null) {
                                        individual.ProductBrowseEngagement.sort();
                                        System.debug('Product Browse Engagement: ' + String.valueOf(individual.ProductBrowseEngagement));
                                        List<Map<String, Object>> productBrowseList = new List<Map<String, Object>>();                                        
                                        // Iterate through ProductBrowseEngagements
                                        for (RealTimeDataGraphResponse.ProductBrowseEngagement engagement : individual.ProductBrowseEngagement) {
                                            System.debug('Engagement ID: ' + engagement.Id);
                                            System.debug('Engagement Type: ' + engagement.EngagementTypeId);
                                            System.debug('Product ID: ' + engagement.ProductId);
                                            System.debug('Product Browse Created Date: ' + engagement.CreatedDate);
                                            /**
                                                    {
                                                        "ssot__IndividualId__c": "0B803C90-8BCC-4821-AE1C-EBC1387B4EC2",
                                                        "ssot__CreatedDate__c": "2025-01-22T04:28:51.544Z",
                                                        "ssot__EngagementChannelActionId__c": "View Catalog Object",
                                                        "ssot__EngagementTypeId__c": "catalog",
                                                        "ssot__Id__c": "9BAF9A01-DB7C-460C-83FD-EF753E8447B3",
                                                        "ssot__ProductId__c": "mens-suit-001",
                                                        "ssot__EngagementChannelId__c": "mobile",
                                                        "ssot__Name__c": "View Catalog Object"
                                                    }                                             * 
                                             * 
                                             */
                                            Map<String, Object> browseData = new Map<String, Object>{
                                                'browseEngagementId' => engagement.Id,                                                
                                                'browseEngagementName' => engagement.Name,
                                                'browseProductId' => engagement.ProductId,
                                                'browseEngagementChannelActionId' => engagement.EngagementChannelActionId,
                                                'browseEngagementType' => engagement.EngagementTypeId,
                                                'browseCreatedDate' => engagement.CreatedDate
                                            };
                                            productBrowseList.add(browseData);
                                        }  
                                        customerProfile.put('productBrowse', productBrowseList);
                                    }else{
                                        System.debug('Product Browse Engagement is null');
                                    }

                                    if (individual.ShoppingCartEngagement != null) {
                                        individual.ShoppingCartEngagement.sort();
                                        System.debug('Shopping Cart Engagement: ' + String.valueOf(individual.ShoppingCartEngagement));
                                        List<Map<String, Object>> shoppingCartList = new List<Map<String, Object>>();                                        
                                        // Iterate through ShoppingCartEngagements
                                        for (RealTimeDataGraphResponse.ShoppingCartEngagement cartEngagement : individual.ShoppingCartEngagement) {
                                            System.debug('Cart Engagement ID: ' + cartEngagement.Id);
                                            System.debug('Product ID: ' + cartEngagement.ProductId);
                                            System.debug('Product Price: ' + cartEngagement.ProductPriceAmount);
                                            System.debug('Product Quantity: ' + cartEngagement.ProductQuantity);
                                            System.debug('Cart Engagement Created Date: ' + cartEngagement.CreatedDate);
                                            Map<String, Object> cartData = new Map<String, Object>{

                                                'cartEngagementId' => cartEngagement.Id,
                                                'cartProductId' => cartEngagement.ProductId,
                                                'cartProductPrice' => cartEngagement.ProductPriceAmount,
                                                'cartProductQuantity' => cartEngagement.ProductQuantity,
                                                'cartCreatedDate' => cartEngagement.CreatedDate
                                            };
                                            shoppingCartList.add(cartData);                                            
                                        }
                                        customerProfile.put('shoppingCart', shoppingCartList);
                                    }else{
                                        System.debug('Shopping Cart Engagement is null');
                                    }
                       
                                } //end of for (RealTimeDataGraphResponse.Individual individual : unifiedLink.Individual)                                
                                
                            } //end of if (unifiedLink.Individual != null)


                        } // end of for (RealTimeDataGraphResponse.UnifiedLink unifiedLink : parsedBlob.UnifiedLinkssotIndividualI1)
                    }// end of if (parsedBlob.UnifiedLinkssotIndividualI1 != null)

                    
                }
            }                
        }catch(Exception e){
            throw new CustomException('Error parsing JSON: ' + e.getMessage());
        }


        
        
        if (jsonResponse.getStatusCode() == 200) {

            // Create a JSON string from RealTimeDataGraphResponse object
            structuredResponse.put('customerProfile', customerProfile);
            System.debug(JSON.serialize(structuredResponse));

            //return jsonResponse.getBody();
            return JSON.serialize(structuredResponse);
        } else {
            throw new AuraHandledException('Error calling Data Graph API: ' + jsonResponse.getStatus());
        }
    }

    private static Map<String, Object> sortEngagements(Map<String, Object> jsonData) {
        List<Object> dataList = (List<Object>) jsonData.get('data');
        for (Object dataItem : dataList) {
            Map<String, Object> dataItemMap = (Map<String, Object>) dataItem;
            String jsonBlob = (String) dataItemMap.get('json_blob');
            Map<String, Object> parsedBlob = (Map<String, Object>) JSON.deserializeUntyped(jsonBlob);
            List<Object> unifiedLinks = (List<Object>) parsedBlob.get('UnifiedLinkssotIndividualI1');
            
            for (Object link : unifiedLinks) {
                Map<String, Object> linkMap = (Map<String, Object>) link;
                List<Object> individuals = (List<Object>) linkMap.get('Individual');
                
                for (Object ind : individuals) {
                    Map<String, Object> individual = (Map<String, Object>) ind;
                    sortEngagementList(individual, 'ProductBrowseEngagement');
                    sortEngagementList(individual, 'ShoppingCartEngagement');
                }
            }
            
            dataItemMap.put('json_blob', JSON.serialize(parsedBlob));
        }
        return jsonData;
    }    

    private static void sortEngagementList(Map<String, Object> individual, String engagementType) {
        List<Object> engagements = (List<Object>) individual.get(engagementType);
        if (engagements != null) {
            engagements.sort(new EngagementComparator());
        }
    }

    private class EngagementComparator implements Comparator<Object> {
        public Integer compare(Object obj1, Object obj2) {
            Integer result = 0;
            try {
                Map<String, Object> eng1 = (Map<String, Object>) obj1;
                Map<String, Object> eng2 = (Map<String, Object>) obj2;
                
                String dateStr1 = (String) eng1.get('CreatedDate');
                String dateStr2 = (String) eng2.get('CreatedDate');
    
                // Parse ISO 8601 date strings
                DateTime date1 = (DateTime) JSON.deserialize('"' + dateStr1 + '"', DateTime.class);
                DateTime date2 = (DateTime) JSON.deserialize('"' + dateStr2 + '"', DateTime.class);
    
                System.debug('date1: ' + date1);
                System.debug('date2: ' + date2);
                result = date2 > date1 ? 1 : (date2 < date1 ? -1 : 0);
            } catch(Exception e) {
                System.debug('EngagementComparator: Error parsing JSON: ' + e.getMessage());
                result = 0; // Return 0 to keep original order in case of error
            }
            
            return result;
        }
    }
}