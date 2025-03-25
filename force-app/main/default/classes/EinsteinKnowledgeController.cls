public with sharing class EinsteinKnowledgeController {
    
    @InvocableMethod(CapabilityType = 'PromptTemplateType://einstein_gpt__fieldCompletion' category = 'Prompt')
    public static List<Response> einsteinKnowledgeReplies(List<Request> topic) {
        List<Response> responses = new List<Response>();
        Response response = new Response();
        String question = topic[0].RelatedEntity;
        //Set topic variable with related question to find similar records to the Question record 
        ConnectApi.CdpQueryInput input = new ConnectApi.CdpQueryInput();
        String query = 'select v.score__c, rc.chunk__c, rc.DataSource__c, rc.DataSourceObject__c ' +
                    'FROM vector_search(table(Email_Message_vector__dlm),  \'' + question + '\', \'\', 6) v ' +
                    'JOIN Email_Message_chunk__dlm rc ON v.RecordId__c = rc.RecordId__c ' +
                    'ORDER BY v.score__c DESC ' +
                    'LIMIT 6';
        System.debug('query: ' + query);
        input.sql = query;
        ConnectApi.CdpQueryOutput output = ConnectApi.CdpQuery.queryANSISql(input);
        List<Object> data = output.data;
        for (Object obj : data) {
            System.debug('obj: ' + obj);
        }
        return responses;
    }

    // All inputs will be passed into the IA
    public class Request {
        @InvocableVariable
        public String RelatedEntity;
    }

    public class Response {
        @InvocableVariable
        public String Prompt;
    }    
}