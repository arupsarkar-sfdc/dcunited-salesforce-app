public with sharing class C360Account_Cases_Invocable {
    private static String className = 'C360Account_Cases_Invocable';
    private static String DATE_FORMAT = 'MM/dd/yyyy h:mma z';
    private static String TIMEZONE = 'PST';

    @InvocableMethod(label='C360Account-GetCases' description='Get Account Cases' category='Data Cloud')
    public static List<CaseDataResponse> getCases(List<Input> inputList) {

        List<CaseDataResponse> responseList = new List<CaseDataResponse>();
        for (Input input: inputList) {
            System.debug(LoggingLevel.DEBUG, className + ' > getCases - input: ' + input);

            long startTime = System.currentTimeMillis();
            List<CaseData> dataList = new List<CaseData>();

            List<C360UnifiedAccountController.CaseData> dmoResponseList = C360UnifiedAccountController.getCases(input.dataSpaceName, input.dataSpacePrefix, input.accountNumber, input.resultsLimit, input.consumerOrg);
            System.debug(LoggingLevel.DEBUG, className + ' > getCases - dmoResponseList: ' + dmoResponseList.size());
            for (C360UnifiedAccountController.CaseData dmo : dmoResponseList) {
                CaseData data = new CaseData();
                data.caseNumber = dmo.caseNumber;
                data.casePriorityId = dmo.casePriority;
                data.caseStatusId = dmo.caseStatus;
                data.subject = dmo.subject;
                data.description = dmo.description;
                data.createdDate = dmo.createdDate.format(DATE_FORMAT, TIMEZONE);
                data.lastModifiedDate = dmo.lastModifiedDate.format(DATE_FORMAT, TIMEZONE);
                data.dataSourceName = dmo.dataSourceName;
                dataList.add(data);
            }

            CaseDataResponse response = new CaseDataResponse();
            response.caseDataList = dataList;
            response.caseDataString = JSON.serialize(dataList); // serialized string of the JSON for use in the Flow datatable component
            responseList.add(response);
            long elapsedTime = System.currentTimeMillis() - startTime;
            System.debug(LoggingLevel.DEBUG, className + ' > getCases - retrieved: ' + dataList.size() + ' in ' + elapsedTime + ' ms');
        }
        System.debug(LoggingLevel.DEBUG, className + ' > getCases - responseList: ' + responseList);
        return responseList;
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

    public class CaseData {
        @InvocableVariable(label='CaseNumber')
        @AuraEnabled public String caseNumber;

        @InvocableVariable(label='CaseStatusId')
        @AuraEnabled public String caseStatusId;

        @InvocableVariable(label='CasePriorityId')
        @AuraEnabled public String casePriorityId;

        @InvocableVariable(label='Subject')
        @AuraEnabled public String subject;

        @InvocableVariable(label='Description')
        @AuraEnabled public String description;

        @InvocableVariable(label='CreatedDate')
        @AuraEnabled public String createdDate;

        @InvocableVariable(label='LastModifiedDate')
        @AuraEnabled public String lastModifiedDate;

        @InvocableVariable(label='DataSourceName')
        @AuraEnabled public String dataSourceName;
    }

    public class CaseDataResponse {
        @InvocableVariable(label='CaseDataList' required=false)
        @AuraEnabled public List<CaseData> caseDataList;

        @InvocableVariable(label='CaseDataString' required=false)
        @AuraEnabled public String caseDataString;  // serialized string of the JSON for use in the Flow datatable component
    }

}