public with sharing class C360Account_ProductUsages_Invocable {

    private static String className = 'C360Account_ProductUsages_Invocable';

    @InvocableMethod(label='C360Account-GetProductUsages' description='Get Account Product Usages' category='Data Cloud')
    public static List<ProductUsageResponse> getProductUsage(List<Input> inputList) {

        List<ProductUsageResponse> responseList = new List<ProductUsageResponse>();
        for (Input input: inputList) {
            System.debug(LoggingLevel.DEBUG, className + ' > getProductUsage - input: ' + input);

            long startTime = System.currentTimeMillis();
            List<ProductUsage> dataList = new List<ProductUsage>();

            List<C360UnifiedAccountController.ProductUsageData2> ciResponseList = C360UnifiedAccountController.getProductUsages(input.dataSpaceName, input.dataSpacePrefix, input.accountNumber, input.industry);
            System.debug(LoggingLevel.DEBUG, className + ' > getProductUsage - ciResponseList: ' + ciResponseList.size());
            for (C360UnifiedAccountController.ProductUsageData2 ciResponse : ciResponseList) {
                ProductUsage data = new ProductUsage();
                data.productName = ciResponse.productName;
                data.usageMetric = ciResponse.usageMetric;
                data.totalUsage = formatNumber(ciResponse.totalUsage);
                data.avgUsage = formatNumber(ciResponse.avgUsage);
                data.maxUsage = formatNumber(ciResponse.maxUsage);
                data.minUsage = formatNumber(ciResponse.minUsage);
                data.usageMonths = formatNumber(ciResponse.usageMonths);
                dataList.add(data);
            }

            ProductUsageResponse response = new ProductUsageResponse();
            response.productUsageList = dataList;
            response.productUsageString = JSON.serialize(dataList);  // serialized string of the JSON for use in the Flow datatable component
            responseList.add(response);
            long elapsedTime = System.currentTimeMillis() - startTime;
            System.debug(LoggingLevel.DEBUG, className + ' > getProductUsage - retrieved: ' + dataList.size() + ' in ' + elapsedTime + ' ms');
        }
        System.debug(LoggingLevel.DEBUG, className + ' > getProductUsage - responseList: ' + responseList);
        return responseList;
    }

    private static String formatNumber(Integer num) {
        List<String> args = new String[]{'0','number','###,###,###,###'};
        return String.format(num.format(), args);
    }

    public class Input {
        @InvocableVariable(label='DataSpace API Name' required=false)
        @AuraEnabled public String dataSpaceName;

        @InvocableVariable(label='DataSpace Prefix' required=false)
        @AuraEnabled public String dataSpacePrefix;

        @InvocableVariable(label='AccountNumber' required=true)
        @AuraEnabled public String accountNumber;

        @InvocableVariable(label='Industry' required=false) // Tech-Networking 
        @AuraEnabled public String industry;
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

}