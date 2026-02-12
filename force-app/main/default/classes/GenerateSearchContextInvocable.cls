/**
 * @description Invocable class that generates dynamic search context from Case fields
 *              using Salesforce Models API for intelligent context extraction.
 * @group Search Context
 */
public with sharing class GenerateSearchContextInvocable {

    public class Request {
        @InvocableVariable(required=false label='Case Comments')
        public String caseComments;
        
        @InvocableVariable(required=true label='Case Description')
        public String caseDescription;
        
        @InvocableVariable(required=false label='Case Name')
        public String caseName;
        
        @InvocableVariable(required=true label='Case Subject')
        public String caseSubject;
    }

    public class Response {
        @InvocableVariable(label='Success')
        public Boolean success;
        
        @InvocableVariable(label='Message')
        public String message;
        
        @InvocableVariable(label='Search Context')
        public String searchContext;
        
        @InvocableVariable(label='Keywords')
        public String keywords;
        
        @InvocableVariable(label='Intent Category')
        public String intentCategory;
    }

    @InvocableMethod(label='Generate Search Context' description='Generates intelligent search context from Case fields for knowledge retrieval.')
    public static List<Response> generate(List<Request> requests) {
        List<Response> results = new List<Response>();
        
        if (requests == null || requests.isEmpty()) {
            Response r = new Response();
            r.success = false;
            r.message = 'No requests provided.';
            results.add(r);
            return results;
        }

        for (Request req : requests) {
            Response res = new Response();
            try {
                if (req == null) {
                    res.success = false;
                    res.message = 'Null request item.';
                    results.add(res);
                    continue;
                }

                // Call LLM to generate search context
                String llmResponse = callLLMForSearchContext(req);
                
                // Parse the JSON response
                Map<String, Object> parsedResponse = (Map<String, Object>) JSON.deserializeUntyped(llmResponse);
                
                res.searchContext = (String) parsedResponse.get('search_context');
                res.keywords = (String) parsedResponse.get('keywords');
                res.intentCategory = (String) parsedResponse.get('intent_category');
                res.success = true;
                res.message = 'Search context generated successfully.';
                // print the formatted JSON response for debugging
                System.debug('LLM Response JSON: ' + JSON.serializePretty(parsedResponse));
                
            } catch (Exception e) {
                res.success = false;
                res.message = 'Error: ' + e.getMessage();
                res.searchContext = buildFallbackContext(req);
            }
            results.add(res);
        }
        return results;
    }

    /**
     * @description Calls the LLM API to generate intelligent search context
     */
    private static String callLLMForSearchContext(Request req) {
        aiplatform.ModelsAPI.createGenerations_Request request = new aiplatform.ModelsAPI.createGenerations_Request();
        request.modelName = 'sfdc_ai__DefaultBedrockAnthropicClaude45Opus';

        aiplatform.ModelsAPI_GenerationRequest requestBody = new aiplatform.ModelsAPI_GenerationRequest();
        request.body = requestBody;

        System.debug('Building prompt for LLM callout.');
        System.debug('Request: ' + JSON.serializePretty(req));
        // Build the prompt
        String prompt = buildSearchContextPrompt(req);
        requestBody.prompt = prompt;

        try {
            aiplatform.ModelsAPI modelsAPI = new aiplatform.ModelsAPI();
            aiplatform.ModelsAPI.createGenerations_Response response = modelsAPI.createGenerations(request);
            System.debug('LLM API call successful.');
            System.debug('LLM API Response: ' + JSON.serializePretty(response));
            return response.Code200.generation.generatedText;
        } catch (aiplatform.ModelsAPI.createGenerations_ResponseException e) {
            System.debug('LLM API Error - Response code: ' + e.responseCode);
            System.debug('Exception: ' + e);
            throw new CalloutException('LLM API call failed: ' + e.getMessage());
        }
    }

    /**
     * @description Builds the prompt for search context generation
     */
    private static String buildSearchContextPrompt(Request req) {
        String prompt = 
            'You are a search context optimization assistant for a customer support system. ' +
            'Your task is to analyze the following customer case information and generate an optimized search context ' +
            'that can be used to find relevant knowledge articles, solutions, and documentation.\n\n' +
            
            '=== CASE INFORMATION ===\n' +
            'Case Name: ' + sanitizeInput(req.caseName) + '\n' +
            'Case Subject: ' + sanitizeInput(req.caseSubject) + '\n' +
            'Case Description: ' + sanitizeInput(req.caseDescription) + '\n' +
            'Case Comments: ' + sanitizeInput(req.caseComments) + '\n\n' +
            
            '=== YOUR TASK ===\n' +
            'Analyze the case information above and generate:\n\n' +
            
            '1. **search_context**: A concise, semantic search-optimized paragraph (2-4 sentences) that:\n' +
            '   - Captures the core issue or question the customer is facing\n' +
            '   - Includes relevant technical terms, product names, and error codes if present\n' +
            '   - Removes noise words, greetings, and irrelevant details\n' +
            '   - Is written in a neutral, factual tone suitable for vector similarity search\n' +
            '   - Expands abbreviations and acronyms where appropriate\n\n' +
            
            '2. **keywords**: A comma-separated list of 5-10 high-value search keywords including:\n' +
            '   - Product/feature names\n' +
            '   - Technical terms and error codes\n' +
            '   - Action verbs describing the issue (e.g., "cannot login", "sync failed")\n' +
            '   - Synonyms for key concepts\n\n' +
            
            '3. **intent_category**: Classify the customer intent into ONE of these categories:\n' +
            '   - TROUBLESHOOTING: Customer has a problem or error\n' +
            '   - HOW_TO: Customer wants to learn how to do something\n' +
            '   - BILLING: Payment, subscription, or pricing related\n' +
            '   - ACCOUNT: Account access, settings, or permissions\n' +
            '   - FEATURE_REQUEST: Customer requesting new functionality\n' +
            '   - GENERAL_INQUIRY: General questions or information requests\n' +
            '   - COMPLAINT: Customer expressing dissatisfaction\n' +
            '   - INTEGRATION: API, third-party, or system integration issues\n\n' +
            
            '=== OUTPUT FORMAT ===\n' +
            'Respond ONLY with valid JSON in this exact format (no markdown, no explanation):\n' +
            '{\n' +
            '  "search_context": "Your optimized search context paragraph here",\n' +
            '  "keywords": "keyword1, keyword2, keyword3, keyword4, keyword5",\n' +
            '  "intent_category": "CATEGORY_NAME"\n' +
            '}\n\n' +
            
            '=== RULES ===\n' +
            '- If information is missing or unclear, infer the most likely meaning from context\n' +
            '- Do NOT include PII (names, emails, phone numbers) in the output\n' +
            '- Keep search_context under 500 characters\n' +
            '- Output must be valid parseable JSON\n';

        return prompt;
    }

    /**
     * @description Sanitizes input to prevent prompt injection and handle nulls
     */
    private static String sanitizeInput(String input) {
        if (String.isBlank(input)) {
            return '[Not provided]';
        }
        // Remove potential prompt injection patterns
        String sanitized = input.replaceAll('(?i)(ignore|forget|disregard)\\s+(previous|above|all)', '[filtered]');
        // Limit length to prevent token overflow
        if (sanitized.length() > 2000) {
            sanitized = sanitized.substring(0, 2000) + '... [truncated]';
        }
        return sanitized;
    }

    /**
     * @description Builds a fallback context without LLM if API fails
     */
    private static String buildFallbackContext(Request req) {
        List<String> contextParts = new List<String>();
        
        if (String.isNotBlank(req.caseSubject)) {
            contextParts.add(req.caseSubject);
        }
        if (String.isNotBlank(req.caseDescription)) {
            String desc2 = req.caseDescription.length() > 200 
                ? req.caseDescription.substring(0, 200) + '...' 
                : req.caseDescription;
            contextParts.add(desc2);
        }
        
        return String.join(contextParts, ' | ');
    }
}
