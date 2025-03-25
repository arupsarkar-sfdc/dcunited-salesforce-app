public with sharing class UnstructuredVectorCtrl {

    @InvocableMethod(CapabilityType = 'PromptTemplateType://einstein_gpt__fieldCompletion' category = 'Prompt')
    public static List<Response> vectorSearch(List<Request> requests) {
        List<Response> responses = new List<Response>();
        Response response = new Response();
        //Set topic variable with related question to find similar records to the Question record 
        String topic = requests[0].RelatedEntity.Question__c;
        ConnectApi.CdpQueryInput input = new ConnectApi.CdpQueryInput();        
        System.debug(LoggingLevel.DEBUG, topic);
        String filePath = 'unstructured/TV-WI-58137_CAR-T_Special situation management in CCM 6.0.pdf';
        String sql = 'select s.score__c score, c.RecordId__c id, c.Chunk__c chunk,  r.FilePath__c filepath ' + 
            		'from vector_search(TABLE(Non_Linear_Object_vector__dlm),  \'' + topic + '\', \'\', 2) s ' +
            		'join Non_Linear_Object_chunk__dlm c on s.RecordId__c = c.RecordId__c ' +
                    'join Non_Linear_Object__dlm r on c.SourceRecordId__c = r.FilePath__c ' +
                    'where r.FilePath__c = \'' + filePath + '\' ' +
            		'ORDER BY 1 desc LIMIT 6';       
                    //Investor_Relation_Report_2__dlm
                    //ETag__c, FilePath__c

        System.debug(LoggingLevel.DEBUG, sql);
        input.sql = sql;
        ConnectApi.CdpQueryOutput output = ConnectApi.CdpQuery.queryANSISql(input);
        System.debug(LoggingLevel.DEBUG, output);
        List<Object> data = output.data;
        String scs = '';
        for (Object searchRecord : data) {
            System.debug(LoggingLevel.DEBUG, searchRecord);
            try{
                Map<String, Object> myMap = (Map<String, Object>) JSON.deserializeUntyped(JSON.serialize(searchRecord));
                Map<String, String> sc = new Map<String, String>();
                //adding id to map
                sc.put('id',String.valueOf(myMap.get('id')));
                sc.put('chunk',String.valueOf(myMap.get('chunk')));
                sc.put('filepath',String.valueOf(myMap.get('filepath')));
                scs = scs + JSON.serialize(sc);            
            }catch(Exception ex){
                System.debug(LoggingLevel.DEBUG, ex.getMessage());
            }

        }

        response.Prompt = scs;
        responses.add(response);
        return responses;        
    }

    public class Request {
        @InvocableVariable
        public Question__c RelatedEntity;
    }

    public class Response {
        @InvocableVariable
        public String Prompt;
    }        
}