public with sharing class C360Account_Opportunities_Invocable {
    private static String className = 'C360Account_Opportunities_Invocable';
    static String DATE_FORMAT = 'MM/dd/yyyy';
    private static String DATETIME_FORMAT = 'MM/dd/yyyy h:mma z';
    private static String TIMEZONE = 'PST';

    @InvocableMethod(label='C360Account-GetOpportunities' description='Get Account Opportunities' category='Data Cloud')
    public static List<OpportunityDataResponse> getOpportunities(List<Input> inputList) {

        List<OpportunityDataResponse> responseList = new List<OpportunityDataResponse>();
        for (Input input: inputList) {
            System.debug(LoggingLevel.DEBUG, className + ' > getOpportunities - input: ' + input);

            long startTime = System.currentTimeMillis();
            List<OpportunityData> dataList = new List<OpportunityData>();

            List<C360UnifiedAccountController.OpportunityData> dmoResponseList = C360UnifiedAccountController.getOpportunities(input.dataSpaceName, input.dataSpacePrefix, input.accountNumber, input.resultsLimit, input.consumerOrg);
            System.debug(LoggingLevel.DEBUG, className + ' > getOpportunities - dmoResponseList: ' + dmoResponseList.size());
            for (C360UnifiedAccountController.OpportunityData dmo : dmoResponseList) {
                OpportunityData data = new OpportunityData();
                data.accountNumber = dmo.accountNumber;
                data.name = dmo.name;
                data.totalAmount = '$' + formatNumber(dmo.totalAmount);
                data.stage = dmo.stage;
                data.type = dmo.type;
                data.closeDate = dmo.closeDate.format(DATE_FORMAT, TIMEZONE);
                data.createdDate = dmo.createdDate.format(DATETIME_FORMAT, TIMEZONE);
                data.lastModifiedDate = dmo.lastModifiedDate.format(DATETIME_FORMAT, TIMEZONE);
                data.dataSourceName = dmo.dataSourceName;
                dataList.add(data);
            }

            OpportunityDataResponse response = new OpportunityDataResponse();
            response.opportunityDataList = dataList;
            response.opportunityDataString = JSON.serialize(dataList); // serialized string of the JSON for use in the Flow datatable component
            responseList.add(response);
            long elapsedTime = System.currentTimeMillis() - startTime;
            System.debug(LoggingLevel.DEBUG, className + ' > getOpportunities - retrieved: ' + dataList.size() + ' in ' + elapsedTime + ' ms');
        }
        System.debug(LoggingLevel.DEBUG, className + ' > getOpportunities - responseList: ' + responseList);
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

        @InvocableVariable(label='ResultsLimit' required=true)
        @AuraEnabled public Integer resultsLimit;

        @InvocableVariable(label='ConsumerOrg' required=false)
        @AuraEnabled public String consumerOrg;
    }

    public class OpportunityData {
        @InvocableVariable(label='AccountNumber')
        @AuraEnabled public String accountNumber;

        @InvocableVariable(label='Name')
        @AuraEnabled public String name;

        @InvocableVariable(label='TotalAmount')
        @AuraEnabled public String totalAmount;

        @InvocableVariable(label='Stage')
        @AuraEnabled public String stage;

        @InvocableVariable(label='Type')
        @AuraEnabled public String type;

        @InvocableVariable(label='CloseDate')
        @AuraEnabled public String closeDate;

        @InvocableVariable(label='CreatedDate')
        @AuraEnabled public String createdDate;

        @InvocableVariable(label='LastModifiedDate')
        @AuraEnabled public String lastModifiedDate;

        @InvocableVariable(label='DataSourceName')
        @AuraEnabled public String dataSourceName;
    }

    public class OpportunityDataResponse {
        @InvocableVariable(label='OpportunityDataList' required=false)
        @AuraEnabled public List<OpportunityData> opportunityDataList;

        @InvocableVariable(label='OpportunityDataString' required=false)
        @AuraEnabled public String opportunityDataString;  // serialized string of the JSON for use in the Flow datatable component
    }

}