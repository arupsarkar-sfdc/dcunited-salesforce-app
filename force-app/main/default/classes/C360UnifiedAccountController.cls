public with sharing class C360UnifiedAccountController {

    private static String className = 'C360UnifiedAccountController';

    // Data Cloud tenant specific endpoint
    public static String DATA_CLOUD_TENANT_ENDPOINT = 'callout:DataCloud'; // named credential
    public static String DATA_CLOUD_QUERY_API_ENDPOINT = DATA_CLOUD_TENANT_ENDPOINT + '/api/v2/query';

    public class C360DataCloudControllerException extends Exception {} 
    public static String dc_token {get; set;}

    @AuraEnabled(cacheable=true)
    public static String testAuth(String dataSpaceName, String dataSpacePrefix) {
        
        String objectName = 'ssot__Account__dlm';
        if ((String.isNotEmpty(dataSpaceName)) && (String.isNotEmpty(dataSpacePrefix)) && !dataSpaceName.equals('default')) 
        objectName = dataSpacePrefix + '_' + objectName;

        String query = 'SELECT COUNT(*) FROM ' + objectName;

        String dcQuery = '{' + '"sql"' + ':' + '"' + query + '"}';
        System.debug(LoggingLevel.DEBUG, 'query: ' + dcQuery);
        String result = queryDataCloud(dataSpaceName, dcQuery);        
        System.debug(LoggingLevel.DEBUG, 'result: ' + result);
        return result;
    }

    @AuraEnabled(cacheable=true)
    public static String getUnifiedAccountByAccountNumber(String accountNumber) {
        String queryCriteria = '\'' + accountNumber + '\'';        
        
        String query = 'SELECT ssot__Name__c, ssot__Number__c, ssot__AccountTypeId__c, ssot__CreatedDate__c, Data_Source_Name__c FROM UnifiedssotAccountA1__dlm';
        query += ' WHERE ssot__Number__c = ' + queryCriteria + ' LIMIT 1';

        String dcQuery = '{' + '"sql"' + ':' + '"' + query + '"}';
        System.debug(LoggingLevel.DEBUG, 'query: ' + dcQuery);
        String result = queryDataCloud(dcQuery);        
        System.debug(LoggingLevel.DEBUG, 'result: ' + result);
        return result;
    }

    @AuraEnabled(cacheable=true)
    public static List<ProductUsageData> getProductUsageTotal(String dataSpaceName, String dataSpacePrefix, String accountNumber, String industry) {
        System.debug(LoggingLevel.DEBUG, className + ' > getProductUsageTotal - dataSpaceName: ' + dataSpaceName + ', dataSpacePrefix: ' + dataSpacePrefix + ', accountNumber: ' + accountNumber + ', industry: ' + industry);
        
        // calculated insight API name
        String ci = 'Product_Usage_All_Time__cio';
        if ((String.isNotEmpty(dataSpaceName)) && (String.isNotEmpty(dataSpacePrefix)) && !dataSpaceName.equals('default')) 
            ci = dataSpacePrefix + '_' + ci;

        // where clause
        String whereClause = ' WHERE accountnumber__c = \'' + accountNumber + '\'';
        if (String.isNotEmpty(industry)) whereClause += ' AND industry__c = \'' + industry + '\'';
        
        String query = 'SELECT productname__c, totalusage__c FROM ' + ci;
        query += whereClause;
        query += ' ORDER BY 1 ASC';

        String dcQuery = '{' + '"sql"' + ':' + '"' + query + '"}';
        System.debug(LoggingLevel.DEBUG, className + ' > getProductUsageTotal - query: ' + dcQuery);
        String jsonResponse = queryDataCloud(dataSpaceName, dcQuery);    
        System.debug(LoggingLevel.DEBUG, className + ' > getProductUsageTotal - query response: ' + jsonResponse);

        //parse the JSON
        List<ProductUsageData> ciResponseList = new List<ProductUsageData>();
        if (String.isNotEmpty(jsonResponse)) {
            C360_CIResponse_Product_Usage_All_Time parsedResponse = C360_CIResponse_Product_Usage_All_Time.parse(jsonResponse);
            List<List<String>> data = parsedResponse.data;    
            integer row_counter = 0;
            for(List<String> row : data) {
                System.debug(LoggingLevel.DEBUG, className + ' > getProductUsageTotal - row value: ' + row);
                ProductUsageData ciResponse = new ProductUsageData();
                integer col_counter = 0;
                for(String col : row) {
                    if (col_counter == 0) {
                        ciResponse.productName = col;
                    } else if(col_counter == 1) {
                        ciResponse.totalUsage = Math.round(Decimal.valueOf(col));
                        ciResponseList.add(ciResponse);              
                    }
                    System.debug(LoggingLevel.DEBUG, className + ' > getProductUsageTotal - col value: ' + col);
                    col_counter++;
                }
                row_counter++;
            }
        }

        System.debug(LoggingLevel.DEBUG, className + ' > getProductUsageTotal - ciResponseList: ' + ciResponseList);
        return ciResponseList;
    }

    @AuraEnabled(cacheable=true)
    public static List<ProductUsageData2> getProductUsages(String dataSpaceName, String dataSpacePrefix, String accountNumber, String industry) {
        System.debug(LoggingLevel.DEBUG, className + ' > getProductUsages - dataSpaceName: ' + dataSpaceName + ', dataSpacePrefix: ' + dataSpacePrefix + ', accountNumber: ' + accountNumber + ', industry: ' + industry);

        // calculated insight API name
        String ci = 'Product_Usage_By_Account__cio'; 
        if ((String.isNotEmpty(dataSpaceName)) && (String.isNotEmpty(dataSpacePrefix)) && !dataSpaceName.equals('default')) 
            ci = dataSpacePrefix + '_' + ci;

        // where clause
        String whereClause = ' WHERE accountnumber__c = \'' + accountNumber + '\'';
        if (String.isNotEmpty(industry)) whereClause += ' AND industry__c = \'' + industry + '\'';
        
        String query = 'SELECT productname__c, usagemetric__c, totalusage__c, avgusage__c, maxusage__c, minusage__c, usagemonths__c FROM ' + ci;
        query += whereClause;
        query += ' ORDER BY 1 ASC';

        String dcQuery = '{' + '"sql"' + ':' + '"' + query + '"}';
        System.debug(LoggingLevel.DEBUG, className + ' > getProductUsages - query: ' + dcQuery);
        String jsonResponse = queryDataCloud(dataSpaceName, dcQuery);    
        System.debug(LoggingLevel.DEBUG, className + ' > getProductUsages - query response: ' + jsonResponse);

        //parse the JSON
        List<ProductUsageData2> ciResponseList = new List<ProductUsageData2>();
        if (String.isNotEmpty(jsonResponse)) {
            C360_CIResponse_Product_Usages parsedResponse = C360_CIResponse_Product_Usages.parse(jsonResponse);
            List<List<String>> data = parsedResponse.data;    
            integer row_counter = 0;
            for(List<String> row : data) {
                System.debug(LoggingLevel.DEBUG, className + ' > getProductUsages - row value: ' + row);
                ProductUsageData2 ciResponse = new ProductUsageData2();
                integer col_counter = 0;
                for(String col : row) {
                    System.debug(LoggingLevel.DEBUG, className + ' > getProductUsages - col value: ' + col);
                    if (col_counter == 0) {
                        ciResponse.productName = col;
                    } else if(col_counter == 1) {
                        ciResponse.usageMetric = col;
                    } else if(col_counter == 2) {
                        ciResponse.totalUsage = Math.round(Decimal.valueOf(col));
                    } else if(col_counter == 3) {
                        ciResponse.avgUsage = Math.round(Decimal.valueOf(col));
                    } else if(col_counter == 4) {
                        ciResponse.maxUsage = Math.round(Decimal.valueOf(col));
                    } else if(col_counter == 5) {
                        ciResponse.minUsage = Math.round(Decimal.valueOf(col));
                    } else if(col_counter == 6) {
                        ciResponse.usageMonths = Math.round(Decimal.valueOf(col));
                        ciResponseList.add(ciResponse); 
                    }
                    col_counter++;
                }
                row_counter++;
            }
        }

        System.debug(LoggingLevel.DEBUG, className + ' > getProductUsages - ciResponseList: ' + ciResponseList);
        return ciResponseList;
    }

    @AuraEnabled(cacheable=true)
    public static List<OpptyInsightsData> getOpptyInsights(String dataSpaceName, String dataSpacePrefix, String accountNumber) {
        System.debug(LoggingLevel.DEBUG, className + ' > getOpptyInsights - dataSpaceName: ' + dataSpaceName + ', dataSpacePrefix: ' + dataSpacePrefix + ', accountNumber: ' + accountNumber);
        String queryCriteria = '\'' + accountNumber + '\'';

        // calculated insight API name
        String ci = 'Opportunities_Total_Won__cio';
        if ((String.isNotEmpty(dataSpaceName)) && (String.isNotEmpty(dataSpacePrefix))) ci = dataSpacePrefix + '_' + ci;

        // TEMP FIX for Danielle's different named CI
        if (dataSpacePrefix == 'FEI') ci = 'FEI_Opportunities_Won__cio';

        String query = 'SELECT totalamountwon__c FROM ' + ci;
        query += ' WHERE accountnumber__c = ' + queryCriteria;

        String dcQuery = '{' + '"sql"' + ':' + '"' + query + '"}';
        System.debug(LoggingLevel.DEBUG, className + ' > getOpptyInsights - query: ' + dcQuery);
        String jsonResponse = queryDataCloud(dataSpaceName, dcQuery);    
        System.debug(LoggingLevel.DEBUG, className + ' > getOpptyInsights - query response: ' + jsonResponse);

        //parse the JSON
        List<OpptyInsightsData> ciResponseList = new List<OpptyInsightsData>();
        if (String.isNotEmpty(jsonResponse)) {
            C360_CIResponse_OpptysWon parsedResponse = C360_CIResponse_OpptysWon.parse(jsonResponse);
            List<List<String>> data = parsedResponse.data;
            integer row_counter = 0;
            for(List<String> row : data) {
                System.debug(LoggingLevel.DEBUG, className + ' > getOpptyInsights - row value: ' + row);
                OpptyInsightsData ciResponse = new OpptyInsightsData();
                integer col_counter = 0;
                for(String col : row) {
                    if(col_counter == 0) {
                        ciResponse.totalAmountWon = Math.round(Decimal.valueOf(col));
                        ciResponseList.add(ciResponse);  
                    } 
                    System.debug(LoggingLevel.DEBUG, className + ' > getOpptyInsights - col value: ' + col);
                    col_counter++;
                }
                row_counter++;
            }
        }

        System.debug(LoggingLevel.DEBUG, className + ' > getOpptyInsights - ciResponseList: ' + ciResponseList);
        return ciResponseList;
    }

    @AuraEnabled(cacheable=true)
    public static List<CaseData> getCases(String dataSpaceName, String dataSpacePrefix, String accountNumber, Integer resultsLimit, String consumerOrg) {
        System.debug(LoggingLevel.DEBUG, className + ' > getCases - dataSpaceName: ' + dataSpaceName + ', dataSpacePrefix: ' + dataSpacePrefix + ', accountNumber: ' + accountNumber + ', resultsLimit: ' + resultsLimit + ', consumerOrg: ' + consumerOrg);
        String queryCriteria = 'UnifiedssotAccountA1__dlm.ssot__Number__c = \'' + accountNumber + '\'';
        if(String.isNotBlank(consumerOrg)) queryCriteria += ' AND ssot__Case__dlm.Data_Source_Name__c != \'' + consumerOrg + '\'';

        String queryLimit = ' LIMIT ' + resultsLimit;

        if (String.isEmpty(dataSpaceName)) dataSpaceName = 'default';

        if (String.isEmpty(dataSpacePrefix)) dataSpacePrefix = 'ssot__';
        else if (String.isNotEmpty(dataSpacePrefix)) dataSpacePrefix += '_';
        System.debug(LoggingLevel.DEBUG, className + ' > getCases - dataSpacePrefix: ' + dataSpacePrefix);

        // Case DMO API name
        String objectName = 'Case__dlm'; //ssot__Case__dlm
        if ((String.isNotEmpty(dataSpaceName)) && (String.isNotEmpty(dataSpacePrefix))) objectName = dataSpacePrefix + objectName;

        String query;

        /*
        if (dataSpaceName.equals('default')) query = 'SELECT ssot__CaseNumber__c, ssot__CaseStatusId__c, ssot__CasePriorityId__c, ssot__Subject__c, ssot__Description__c, ssot__CreatedDate__c, ssot__LastModifiedDate__c, Data_Source_Name__c AS DataSourceName FROM ' + objectName;
        else query = 'SELECT CaseNumber__c, CaseStatusId__c, CasePriorityId__c, Subject__c, Description__c, CreatedDate__c, LastModifiedDate__c FROM ' + objectName;
        query += ' WHERE Account_Number__c = ' + queryCriteria;
        query += ' ORDER BY 6 DESC';
        */

        query = 'SELECT ssot__CaseNumber__c, ssot__CaseStatusId__c, ssot__CasePriorityId__c, ssot__Subject__c, ssot__Case__dlm.ssot__Description__c, ssot__Case__dlm.ssot__CreatedDate__c, ssot__Case__dlm.ssot__LastModifiedDate__c, ssot__Case__dlm.Data_Source_Name__c AS DataSourceName';
        query += ' FROM UnifiedssotAccountA1__dlm JOIN UnifiedLinkssotAccountA1__dlm ON (UnifiedssotAccountA1__dlm.ssot__Id__c = UnifiedLinkssotAccountA1__dlm.UnifiedRecordId__c) JOIN ssot__Case__dlm ON (UnifiedLinkssotAccountA1__dlm.SourceRecordId__c = ssot__Case__dlm.ssot__AccountId__c)';
        query += ' WHERE ' + queryCriteria;
        query += ' ORDER BY 6 DESC';
        if (resultsLimit > -1) query += queryLimit;

        String dcQuery = '{' + '"sql"' + ':' + '"' + query + '"}';
        System.debug(LoggingLevel.DEBUG, className + ' > getCases - query: ' + dcQuery);
        String jsonResponse = queryDataCloud(dataSpaceName, dcQuery);    
        System.debug(LoggingLevel.DEBUG, className + ' > getCases - query response: ' + jsonResponse);

        //parse the JSON
        List<CaseData> dmoResponseList = new List<CaseData>();
        if (String.isNotEmpty(jsonResponse)) {
            C360_DMOResponse_Case parsedResponse = C360_DMOResponse_Case.parse(jsonResponse);
            List<List<String>> data = parsedResponse.data;
            integer row_counter = 0;
            for(List<String> row : data) {
                System.debug(LoggingLevel.DEBUG, className + ' > getCases - row value: ' + row);
                CaseData dmoResponse = new CaseData();
                integer col_counter = 0;
                for(String col : row) {
                    if(col_counter == 0) {
                        dmoResponse.caseNumber = col;
                    } else if(col_counter == 1) {
                        dmoResponse.caseStatus = col;
                    } else if(col_counter == 2) {
                        dmoResponse.casePriority = col;
                    } else if(col_counter == 3) {
                        dmoResponse.subject = col;
                    } else if(col_counter == 4) {
                        dmoResponse.description = col;
                    } else if(col_counter == 5) {
                        dmoResponse.createdDate = DateTime.valueOf(col);
                    } else if(col_counter == 6) {
                        dmoResponse.lastModifiedDate = DateTime.valueOf(col);
                    } else if(col_counter == 7) {
                        dmoResponse.dataSourceName = col;
                        dmoResponseList.add(dmoResponse);
                    } 
                    //System.debug(LoggingLevel.DEBUG, className + ' > getCases - col #: ' + col_counter + ', col value: ' + col);
                    col_counter++;
                }
                row_counter++;
            }
        }

        System.debug(LoggingLevel.DEBUG, className + ' > getCases - dmoResponseList: ' + dmoResponseList.size());
        return dmoResponseList;
    }

    @AuraEnabled(cacheable=true)
    public static List<OpportunityData> getOpportunities(String dataSpaceName, String dataSpacePrefix, String accountNumber, Integer resultsLimit, String consumerOrg) {
        System.debug(LoggingLevel.DEBUG, className + ' > getOpportunities - dataSpaceName: ' + dataSpaceName + ', dataSpacePrefix: ' + dataSpacePrefix + ', accountNumber: ' + accountNumber + ', resultsLimit: ' + resultsLimit + ', consumerOrg: ' + consumerOrg);
        String queryCriteria = 'UnifiedssotAccountA1__dlm.ssot__Number__c = \'' + accountNumber + '\'';
        queryCriteria += ' AND ssot__OpportunityStageId__c != \'Closed Lost\' AND ssot__OpportunityStageId__c != \'Closed Won\'';
        if(String.isNotBlank(consumerOrg)) queryCriteria += ' AND ssot__Opportunity__dlm.Data_Source_Name__c != \'' + consumerOrg + '\'';

        String queryLimit = ' LIMIT ' + resultsLimit;

        if (String.isEmpty(dataSpaceName)) dataSpaceName = 'default';

        if (String.isEmpty(dataSpacePrefix)) dataSpacePrefix = 'ssot__';
        else if (String.isNotEmpty(dataSpacePrefix)) dataSpacePrefix += '_';
        System.debug(LoggingLevel.DEBUG, className + ' > getOpportunities - dataSpacePrefix: ' + dataSpacePrefix);

        // (in google workshop prep org) SELECT UnifiedssotAccountSsot__dlm.ssot__Number__c AS AccountNumber, ssot__Opportunity__dlm.ssot__TotalAmount__c AS TotalAmount FROM UnifiedssotAccountSsot__dlm JOIN UnifiedLinkssotAccountSsot__dlm ON (UnifiedssotAccountSsot__dlm.ssot__Id__c = UnifiedLinkssotAccountSsot__dlm.UnifiedRecordId__c) JOIN ssot__Opportunity__dlm ON (UnifiedLinkssotAccountSsot__dlm.SourceRecordId__c = ssot__Opportunity__dlm.Account_Id__c) WHERE UnifiedssotAccountSsot__dlm.ssot__Number__c = ''
        String query;
        if (dataSpaceName.equals('default')) {           
            query = 'SELECT UnifiedssotAccountA1__dlm.ssot__Number__c AS AccountNumber, ssot__Opportunity__dlm.ssot__Name__c AS Name, ssot__Opportunity__dlm.ssot__TotalAmount__c AS TotalAmount, ssot__Opportunity__dlm.ssot__OpportunityStageId__c AS Stage, ssot__Opportunity__dlm.ssot__OpportunityTypeId__c AS Type, ssot__Opportunity__dlm.ssot__CloseDate__c AS CloseDate, ssot__Opportunity__dlm.ssot__CreatedDate__c AS CreatedDate, ssot__Opportunity__dlm.ssot__LastModifiedDate__c AS LastModifiedDate, ssot__Opportunity__dlm.Data_Source_Name__c AS DataSourceName';
            query += ' FROM UnifiedssotAccountA1__dlm JOIN UnifiedLinkssotAccountA1__dlm ON (UnifiedssotAccountA1__dlm.ssot__Id__c = UnifiedLinkssotAccountA1__dlm.UnifiedRecordId__c) JOIN ssot__Opportunity__dlm ON (UnifiedLinkssotAccountA1__dlm.SourceRecordId__c = ssot__Opportunity__dlm.Account_ID__c)';
            query += ' WHERE ' + queryCriteria;
            query += ' ORDER BY 6 DESC'; // CloseDate
            if (resultsLimit > -1) query += queryLimit;
         }
        
        String dcQuery = '{' + '"sql"' + ':' + '"' + query + '"}';
        System.debug(LoggingLevel.DEBUG, className + ' > getOpportunities - query: ' + dcQuery);
        String jsonResponse = queryDataCloud(dataSpaceName, dcQuery);    
        //System.debug(LoggingLevel.DEBUG, className + ' > getOpportunities - query response: ' + jsonResponse);

        //parse the JSON
        List<OpportunityData> dmoResponseList = new List<OpportunityData>();
        if (String.isNotEmpty(jsonResponse)) {
            C360_DMOResponse_Opportunity parsedResponse = C360_DMOResponse_Opportunity.parse(jsonResponse);
            List<List<String>> data = parsedResponse.data;
            integer row_counter = 0;
            for(List<String> row : data) {
                System.debug(LoggingLevel.DEBUG, className + ' > getOpportunities - row value: ' + row);
                OpportunityData dmoResponse = new OpportunityData();
                integer col_counter = 0;
                for(String col : row) {
                    if(col_counter == 0) {
                        dmoResponse.accountNumber = col;
                    } else if(col_counter == 1) {
                        dmoResponse.name = col;
                    } else if(col_counter == 2) {
                        col = (col == null) ? '0' : col;
                        dmoResponse.totalAmount = Math.round(Decimal.valueOf(col));
                    } else if(col_counter == 3) {
                        dmoResponse.stage = col;
                    } else if(col_counter == 4) {
                        col = (col == null) ? '' : col;
                        dmoResponse.type = col;
                    } else if(col_counter == 5) {
                        dmoResponse.closeDate = DateTime.valueOf(col);
                    } else if(col_counter == 6) {
                        dmoResponse.createdDate = DateTime.valueOf(col);
                    } else if(col_counter == 7) {
                        dmoResponse.lastModifiedDate = DateTime.valueOf(col);
                    } else if(col_counter == 8) {
                        dmoResponse.dataSourceName = col;
                        dmoResponseList.add(dmoResponse);
                    } 
                    
                    //System.debug(LoggingLevel.DEBUG, className + ' > getOpportunities - col #: ' + col_counter + ', col value: ' + col + ', dmoResponseList: ' + dmoResponseList.size());
                    col_counter++;
                }
                row_counter++;
            }
        }

        System.debug(LoggingLevel.DEBUG, className + ' > getOpportunities - dmoResponseList: ' + dmoResponseList.size());
        return dmoResponseList;
    }

    // added for the MuleSoft Invoices vignette
    @AuraEnabled(cacheable=true)
    public static List<InvoiceData> getInvoices(String accountNumber) {

        // this is a return apex object
        List<InvoiceData> invoiceDatas = new List<InvoiceData>();

        // the fields have to be in this exact order to work
        String query = 'SELECT cust_number__c, DataSource__c, DataSourceObject__c, doc_id__c, document_create_date__c, due_in_date__c, eventdate__c, invoice_currency__c, invoice_id__c, isopen__c, name_customer__c, total_open_amount__c FROM MuleSoft_Invoices_invoice_F38E704F__dlm WHERE cust_number__c =\'' + accountNumber + '\' LIMIT 10';
        // JSON for the win
        String dcQuery = '{"sql":"' + query + '"}';
        // this will need to be parsed
        String queryResults = C360UnifiedAccountController.queryDataCloud(dcQuery);

        if (String.isNotEmpty(queryResults)) {

            // parse to the Data Cloud API response
            C360_DMOResponse_Invoice parsedResponse = C360_DMOResponse_Invoice.parse(queryResults);
            // pull out the list of lists that represent the object data
            List<List<String>> data = parsedResponse.data;

            // this is a mapping exercise because Data Cloud returns object fields in lists of strings
            for(List<String> row:data) {
                System.debug(LoggingLevel.DEBUG, className + ' > getInvoices - row value: ' + row);
                InvoiceData inData = new InvoiceData();
                inData.custNumber = row[0];
                inData.DataSource = row[1];
                inData.DataSourceObject = row[2];
                if(String.isNotBlank(row[3])) inData.docId = Math.round(Decimal.valueOf(row[3])); // integer
                if(String.isNotBlank(row[4])) inData.documentCreateDate = Date.valueOf(row[4]);
                if(String.isNotBlank(row[5])) inData.dueInDate = Date.valueOf(row[5]);
                if(String.isNotBlank(row[6])) inData.eventDate = DateTime.valueOf(row[6]);
                inData.invoiceCurrency = row[7];
                inData.invoiceId = row[8];
                if(String.isNotBlank(row[9])) inData.isOpen = Math.round(Decimal.valueOf(row[9])); // integer
                inData.nameCustomer = row[10];
                if(String.isNotBlank(row[11])) inData.totalOpenAmount = Decimal.valueOf(row[11]).setScale(2); // currency

                // add completed object to invoice list
                invoiceDatas.add(inData);
            }
        }
        // return the apex object
        return invoiceDatas;
    }

    private static String queryDataCloud(String query) {
        // use default DataSpace
        return queryDataCloud(null, query);
    }

    public static String getDataCloudToken(String dataSpaceName) {
        System.debug(LoggingLevel.DEBUG, className + ' > getDataCloudToken - dataSpaceName: ' + dataSpaceName);
        C360AuthController dcAuth = new C360AuthController(dataSpaceName);        
        return dcAuth.dc_token;
    } 
    
	private static String queryDataCloud(String dataSpaceName, String query) {
        System.debug(LoggingLevel.DEBUG, className + ' > queryDataCloud - dataSpaceName: ' + dataSpaceName + ', query ' + query);
		dc_token = getDataCloudToken(dataSpaceName);
        String result = '';

        System.debug(LoggingLevel.DEBUG, className + ' > endpoint: ' + DATA_CLOUD_QUERY_API_ENDPOINT); 
        Http h = new Http();
        HttpRequest req = new HttpRequest();
        req.setMethod('POST');
        req.setHeader('Content-Type', 'application/json;charset=UTF-8');
        req.setHeader('Authorization', 'Bearer ' + dc_token);
        req.setBody(query);        
		req.setEndpoint(DATA_CLOUD_QUERY_API_ENDPOINT);

        HttpResponse res = h.send(req);
        System.debug(LoggingLevel.DEBUG, className + ' > queryDataCloud - response body: ' + res.getBody());  
        System.debug(LoggingLevel.DEBUG, className + ' > queryDataCloud - status code: ' + res.getStatusCode());  
        if(res.getStatusCode() != 200) {
            System.debug(LoggingLevel.ERROR, className + ' > queryDataCloud - error: ' + res.getStatus());  
            throw new C360DataCloudControllerException(res.getBody());
        }
 
        try{
            result = res.getBody().replaceAll('__c','').replaceAll('ssot__','');
        } catch(exception ex) {
            System.debug(LoggingLevel.ERROR, className + ' > queryDataCloud - error ' + ex.getMessage());
            throw new C360DataCloudControllerException(ex.getMessage());
        }
        return result;
    }

    public class ProductUsageData {
        public String productName {get; set;}
        public Integer totalUsage {get; set;}
    }

    public class ProductUsageData2 {
        public String productName {get; set;}
        public String usageMetric {get; set;}
        public Integer totalUsage {get; set;}
        public Integer avgUsage {get; set;}
        public Integer maxUsage {get; set;}
        public Integer minUsage {get; set;} 
        public Integer usageMonths {get; set;}
    }

    public class OpptyInsightsData {
        public Integer totalAmountWon {get; set;}
    }

    public class CaseData {
        public String caseNumber {get; set;}
        public String caseStatus {get; set;}
        public String casePriority {get; set;} 
        public String subject {get; set;}
        public String description {get; set;}
        public DateTime createdDate {get; set;}
        public DateTime lastModifiedDate {get; set;}
        public String dataSourceName {get; set;}
    }

    public class OpportunityData {
        public String accountNumber {get; set;}
        public String name {get; set;}
        public Integer totalAmount {get; set;}
        public String stage {get; set;}
        public String type {get; set;}
        public DateTime closeDate {get; set;}
        public DateTime createdDate {get; set;}
        public DateTime lastModifiedDate {get; set;}
        public String dataSourceName {get; set;}
    }

    public class InvoiceData {
        public String custNumber {get;set;}
        public String DataSource {get;set;}
        public String DataSourceObject {get;set;}
        public Integer docId {get;set;}
        public Date documentCreateDate {get;set;}
        public Date dueInDate {get;set;}
        public DateTime eventDate {get;set;}
        public String invoiceCurrency {get;set;}
        public String invoiceId {get;set;}
        public Integer isOpen {get;set;}
        public String nameCustomer {get;set;}
        public Decimal totalOpenAmount {get;set;}
    }

}