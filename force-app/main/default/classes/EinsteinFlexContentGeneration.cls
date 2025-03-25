public with sharing class EinsteinFlexContentGeneration {

    private static String className = 'C360Account_ProductUsages_Invocable';    
    //The api name of the flex prompt builder template should match with Generate_Contextualized_Email
    @InvocableMethod(CapabilityType = 'FlexTemplate://Generate_Contextualized_Email')
    public static List<Response> getPrompt(List<Request> requests) {
        System.debug(LoggingLevel.DEBUG, 'EinsteinFlexContentGeneration > getPrompt');
        Request input = requests[0];
        List<Response> responses = new List<Response>();

        
        Response output = new Response();
        output.Prompt = 'generate a summary using the following info:';
        output.Prompt += '\n' + input.RelatedAccount.Name;
        output.Prompt += '\n' + input.RelatedAccount.AccountNumber;
        output.Prompt += '\n' + input.RelatedAccount.Description;
        output.Prompt += '\n' + input.RelatedAccount.Industry;
        output.Prompt += '\n' + input.RelatedAccount.Type;
        //get the productUsage data
        List<C360UnifiedAccountController.ProductUsageData2> productUsageList = getProductUsage(input.RelatedAccount.AccountNumber, input.RelatedAccount.Industry);
        if(productUsageList.size() > 0) {
            //convert the productUsageList to JSON string 
            String productUsageString = JSON.serialize(productUsageList);
            output.Prompt += '\n' + productUsageString;
        }
        responses.add(output); 
        System.debug(LoggingLevel.DEBUG, 'EinsteinFlexContentGeneration > getPrompt - output: ' + output.Prompt);       

        return responses;
    }

    public static List<C360UnifiedAccountController.ProductUsageData2> getProductUsage(String accountNumber, String accountIndustry) {

        List<C360UnifiedAccountController.ProductUsageData2> responseList = new List<C360UnifiedAccountController.ProductUsageData2>();
        System.debug(LoggingLevel.DEBUG, className + ' > getProductUsage - input: ' + accountNumber + ' - ' + accountIndustry);
        long startTime = System.currentTimeMillis();
        List<ProductUsage> dataList = new List<ProductUsage>();
        accountIndustry = 'Tech-Networking';
        List<C360UnifiedAccountController.ProductUsageData2> ciResponseList = C360UnifiedAccountController.getProductUsages('default', 'default', accountNumber, accountIndustry);
        long elapsedTime = System.currentTimeMillis() - startTime;
        System.debug(LoggingLevel.DEBUG, className + ' > getProductUsage - ciResponseList: ' + ciResponseList.size() + ', elapsed time: ' + elapsedTime + ' ms');
        responseList.addAll(ciResponseList);
        return responseList;
    }

    public class ProductUsage {
        @InvocableVariable(label='Product Name')
        @AuraEnabled public String productName;

        @InvocableVariable(label='Usage Metric')
        @AuraEnabled public String usageMetric;

        @InvocableVariable(label='TotalUsage')
        @AuraEnabled public String totalUsage;

        @InvocableVariable(label='AvgUsage')
        @AuraEnabled public String avgUsage;

        @InvocableVariable(label='MaxUsage')
        @AuraEnabled public String maxUsage;

        @InvocableVariable(label='MinUsage')
        @AuraEnabled public String minUsage;

        @InvocableVariable(label='UsageMonths')
        @AuraEnabled public String usageMonths;
    }

    public class ProductUsageResponse {
        @InvocableVariable(label='ProductUsageList' required=false)
        @AuraEnabled public List<ProductUsage> productUsageList;
    
        @InvocableVariable(label='ProductUsageString' required=false)
        @AuraEnabled public String productUsageString;  // serialized string of the JSON for use in the Flow datatable component
    }

    // Type and API Name of all variables must match the template
    public class Request {
        @InvocableVariable(required=true)
        public Account RelatedAccount;
    }

    public class Response {
        @InvocableVariable
        public String Prompt;
    }
}