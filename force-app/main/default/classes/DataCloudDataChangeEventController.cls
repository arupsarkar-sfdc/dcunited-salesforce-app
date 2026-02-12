public with sharing class DataCloudDataChangeEventController {
    public DataCloudDataChangeEventController() {
        System.debug(LoggingLevel.DEBUG, 'DataCloudDataChangeEventController instantiated.');
    }

    // Wrapper to optionally summarize parsed payload (when possible)
    public class PayloadWrapper {
        public String id;
        public Map<String, Object> attributes;
    }

    // Wrapper to hold processing results for each event (used to separate callouts from DML)
    private class EventProcessingResult {
        public Id caseId;
        public String eventTimestamp;
        public GenerateSearchContextInvocable.Request request;
        public GenerateSearchContextInvocable.Response response;
        public Map<String, Object> baseHeaders;
        public String payloadJson;
    }

    // Build GenerateSearchContextInvocable.Request from CDC payload JSON
    private static GenerateSearchContextInvocable.Request buildSearchContextRequestFromPayload(String payloadJson) {
        GenerateSearchContextInvocable.Request req = new GenerateSearchContextInvocable.Request();
        if (String.isBlank(payloadJson)) {
            req.caseSubject = '[Not provided]';
            req.caseDescription = '[Not provided]';
            req.caseName = '[Not provided]';
            req.caseComments = null;
            return req;
        }
        try {
            Object innerUntyped = JSON.deserializeUntyped(payloadJson);
            if (innerUntyped instanceof Map<String, Object>) {
                Map<String, Object> innerMap = (Map<String, Object>) innerUntyped;
                req.caseSubject = (String) innerMap.get('ssot__Subject__c');
                req.caseDescription = (String) innerMap.get('ssot__EmailMessageText__c');
                req.caseName = (String) innerMap.get('ssot__Name__c');

                List<String> hints = new List<String>();
                String dsObj = (String) innerMap.get('ssot__DataSourceObjectId__c');
                if (!String.isBlank(dsObj)) {
                    hints.add('Source=' + dsObj);
                }
                String msgDt = (String) innerMap.get('ssot__MessageDate__c');
                if (!String.isBlank(msgDt)) {
                    hints.add('MsgDate=' + msgDt);
                }

                if (innerMap.containsKey('relevantResults')) {
                    Object rrUntyped = innerMap.get('relevantResults');
                    if (rrUntyped instanceof List<Object>) {
                        List<Object> rrList = (List<Object>) rrUntyped;
                        Decimal bestScore;
                        String bestChunk;
                        for (Object o : rrList) {
                            if (o instanceof Map<String, Object>) {
                                Map<String, Object> row = (Map<String, Object>) o;
                                Decimal score;
                                if (row.containsKey('Score__c')) {
                                    Object s = row.get('Score__c');
                                    try { score = s == null ? null : Decimal.valueOf(String.valueOf(s)); } catch (Exception ignore) {}
                                }
                                String chunk = (String) row.get('Chunk__c');
                                if (!String.isBlank(chunk) && chunk.length() <= 200) {
                                    if (bestScore == null || (score != null && score > bestScore)) {
                                        bestScore = score != null ? score : bestScore;
                                        bestChunk = chunk;
                                    }
                                }
                            }
                        }
                        if (!String.isBlank(bestChunk)) hints.add('TopTerm=' + bestChunk);
                    }
                }
                req.caseComments = hints.isEmpty() ? null : String.join(hints, '; ');
                if (String.isBlank(req.caseSubject)) req.caseSubject = '[Not provided]';
                if (String.isBlank(req.caseDescription)) req.caseDescription = '[Not provided]';
            } else {
                req.caseSubject = '[Not provided]';
                req.caseDescription = '[Not provided]';
                req.caseName = '[Not provided]';
            }
        } catch (Exception ex) {
            req.caseSubject = '[Not provided]';
            req.caseDescription = '[Not provided]';
            req.caseName = '[Not provided]';
            req.caseComments = 'parseError=' + ex.getMessage();
        }
        return req;
    }

    // Extract Case ID from payload JSON
    private static Id extractCaseIdFromPayload(String payloadJson) {
        if (String.isBlank(payloadJson)) {
            return null;
        }
        try {
            Object untyped = JSON.deserializeUntyped(payloadJson);
            if (untyped instanceof Map<String, Object>) {
                Map<String, Object> payloadMap = (Map<String, Object>) untyped;
                String caseIdStr = (String) payloadMap.get('ssot__CaseId__c');
                if (String.isNotBlank(caseIdStr)) {
                    return Id.valueOf(caseIdStr);
                }
            }
        } catch (Exception ex) {
            System.debug(LoggingLevel.ERROR, 'Error extracting Case ID from payload: ' + ex.getMessage());
        }
        return null;
    }

    // Update Case record with AI-generated classification context
    // Returns the Case to update (DML is done in bulk later)
    private static Case buildCaseUpdateWithClassification(Id caseId, GenerateSearchContextInvocable.Response llmResponse, String eventTimestamp) {
        if (caseId == null) {
            System.debug(LoggingLevel.WARN, 'Cannot update Case: No Case ID provided');
            return null;
        }

        try {
            // Query existing Case to append to description
            List<Case> cases = [SELECT Id, Description FROM Case WHERE Id = :caseId LIMIT 1];
            if (cases.isEmpty()) {
                System.debug(LoggingLevel.WARN, 'Case not found with ID: ' + caseId);
                return null;
            }

            Case caseToUpdate = cases[0];
            String existingDescription = String.isBlank(caseToUpdate.Description) ? '' : caseToUpdate.Description;

            // Build AI classification block
            String aiClassificationBlock = '\n\n' +
                '═══════════════════════════════════════════════════════════════\n' +
                'AI CLASSIFICATION (' + (String.isNotBlank(eventTimestamp) ? eventTimestamp : String.valueOf(Datetime.now())) + ')\n' +
                '───────────────────────────────────────────────────────────────\n';

            if (llmResponse != null && llmResponse.success) {
                aiClassificationBlock += 'Intent Category: ' + (String.isNotBlank(llmResponse.intentCategory) ? llmResponse.intentCategory : 'N/A') + '\n';
                aiClassificationBlock += 'Keywords: ' + (String.isNotBlank(llmResponse.keywords) ? llmResponse.keywords : 'N/A') + '\n';
                aiClassificationBlock += 'Search Context: ' + (String.isNotBlank(llmResponse.searchContext) ? llmResponse.searchContext : 'N/A') + '\n';
            } else {
                String errorMsg = (llmResponse != null && String.isNotBlank(llmResponse.message)) ? llmResponse.message : 'LLM processing failed';
                aiClassificationBlock += 'Status: Classification pending - ' + errorMsg + '\n';
            }
            aiClassificationBlock += '═══════════════════════════════════════════════════════════════';

            // Update Case description
            caseToUpdate.Description = existingDescription + aiClassificationBlock;
            return caseToUpdate;
        } catch (Exception ex) {
            System.debug(LoggingLevel.ERROR, 'Exception building Case update for ' + caseId + ': ' + ex.getMessage());
            return null;
        }
    }

    // Build Debug_Log__c record from processing result (no DML)
    private static Debug_Log__c buildSearchContextDebugLog(EventProcessingResult result) {
        Map<String, Object> body = new Map<String, Object>();
        if (result.baseHeaders != null) body.putAll(result.baseHeaders);
        body.put('caseId', result.caseId);
        body.put('caseUpdated', result.caseId != null);
        body.put('request', new Map<String, Object>{
            'caseSubject' => result.request.caseSubject,
            'caseDescription' => result.request.caseDescription,
            'caseName' => result.request.caseName,
            'caseComments' => result.request.caseComments
        });
        if (result.response != null) {
            body.put('searchContextResult', new Map<String, Object>{
                'success' => result.response.success,
                'message' => result.response.message,
                'searchContext' => result.response.searchContext,
                'keywords' => result.response.keywords,
                'intentCategory' => result.response.intentCategory
            });
        } else {
            body.put('searchContextResult', new Map<String, Object>{
                'success' => false,
                'message' => 'No response from GenerateSearchContextInvocable'
            });
        }

        Debug_Log__c logRec = new Debug_Log__c();
        logRec.Body__c = JSON.serialize(body);
        return logRec;
    }

    // Call LLM and return processing result (NO DML - callout only)
    private static EventProcessingResult callLLMForSearchContext(String payloadJson, Map<String, Object> baseHeaders) {
        EventProcessingResult result = new EventProcessingResult();
        result.payloadJson = payloadJson;
        result.baseHeaders = baseHeaders;
        result.caseId = extractCaseIdFromPayload(payloadJson);
        result.eventTimestamp = baseHeaders != null ? (String) baseHeaders.get('EventPublishDateTime') : null;
        result.request = buildSearchContextRequestFromPayload(payloadJson);

        // Call LLM (this is the only callout)
        List<GenerateSearchContextInvocable.Request> inList = new List<GenerateSearchContextInvocable.Request>{ result.request };
        List<GenerateSearchContextInvocable.Response> outList = GenerateSearchContextInvocable.generate(inList);
        result.response = (outList != null && !outList.isEmpty()) ? outList[0] : null;

        return result;
    }

    public static void processEvents(List<DataObjectDataChgEvent> events) {
        System.debug(LoggingLevel.DEBUG, 'DataCloudDataChangeEventController.processEvents - events: ' + events);

        if (events == null || events.isEmpty()) {
            return;
        }

        // ============================================================
        // PHASE 1: CALLOUTS ONLY - No DML allowed before callouts
        // ============================================================
        
        // Prepare Debug_Log__c records in bulk (no DML in loops)
        List<Debug_Log__c> logsToInsert = new List<Debug_Log__c>();
        
        // Collect LLM processing results (callouts happen here)
        List<EventProcessingResult> llmResults = new List<EventProcessingResult>();

        for (DataObjectDataChgEvent eventRecord : events) {
            // Build a structured body JSON capturing key headers and raw payloads
            Map<String, Object> body = new Map<String, Object>();
            // Required/primary headers from provided schema details
            body.put('EventType', eventRecord.EventType);
            body.put('EventUuid', eventRecord.EventUuid);
            body.put('EventCreationDateTime', eventRecord.EventCreationDateTime);
            body.put('EventPublishDateTime', eventRecord.EventPublishDateTime);
            body.put('EventSchemaVersion', eventRecord.EventSchemaVersion);
            body.put('EventPrompt', eventRecord.EventPrompt);
            body.put('ReplayId', eventRecord.ReplayId);
            body.put('ActionDeveloperName', eventRecord.ActionDeveloperName);
            body.put('SourceObjectDeveloperName', eventRecord.SourceObjectDeveloperName);
            body.put('ProfileIdValue', eventRecord.ProfileIdValue);
            body.put('TraceIdValue', eventRecord.TraceIdValue);
            body.put('Offset', eventRecord.Offset);
            body.put('TriggerEntity', eventRecord.TriggerEntity);

            // Raw payloads
            body.put('PayloadCurrentValue', eventRecord.PayloadCurrentValue);
            body.put('PayloadPrevValue', eventRecord.PayloadPrevValue);
            body.put('PayloadSchema', eventRecord.PayloadSchema);

            // Attempt a lightweight parse summary of current payload if present
            Map<String, Object> parsedSummary = new Map<String, Object>();
            if (String.isNotBlank(eventRecord.PayloadCurrentValue)) {
                try {
                    // Try untyped first to avoid strict schema assumptions
                    Object untyped = JSON.deserializeUntyped(eventRecord.PayloadCurrentValue);
                    // capture a minimal summary, not the entire object again
                    if (untyped instanceof Map<String, Object>) {
                        Map<String, Object> m = (Map<String, Object>) untyped;
                        // add common top-level hints if present
                        if (m.containsKey('id')) {
                            parsedSummary.put('id', m.get('id'));
                        }
                        if (m.containsKey('attributes')) {
                            parsedSummary.put('hasAttributes', true);
                        }
                        parsedSummary.put('topLevelKeysCount', m.keySet().size());
                    } else if (untyped instanceof List<Object>) {
                        List<Object> l = (List<Object>) untyped;
                        parsedSummary.put('isArray', true);
                        parsedSummary.put('length', l.size());
                    } else {
                        // Apex doesn't support Java-style reflection. Use a coarse classification only.
                        String apexType = 'unknown';
                        if (untyped == null) {
                            apexType = 'null';
                        } else if (untyped instanceof String) {
                            apexType = 'String';
                        } else if (untyped instanceof Boolean) {
                            apexType = 'Boolean';
                        } else if (untyped instanceof Integer) {
                            apexType = 'Integer';
                        } else if (untyped instanceof Long) {
                            apexType = 'Long';
                        } else if (untyped instanceof Decimal) {
                            apexType = 'Decimal';
                        } else if (untyped instanceof Double) {
                            apexType = 'Double';
                        } else if (untyped instanceof Date) {
                            apexType = 'Date';
                        } else if (untyped instanceof Datetime) {
                            apexType = 'Datetime';
                        } else {
                            apexType = 'Other';
                        }
                        parsedSummary.put('type', apexType);
                    }
                } catch (Exception ex) {
                    parsedSummary.put('parseError', ex.getMessage());
                }
            }
            body.put('parsedSummary', parsedSummary);

            // Create Debug_Log__c record for raw event
            Debug_Log__c logRec = new Debug_Log__c();
            logRec.Body__c = JSON.serialize(body);
            logsToInsert.add(logRec);

            // Prepare headers for LLM context log
            Map<String, Object> baseHeaders = new Map<String, Object>{
                'EventType' => eventRecord.EventType,
                'EventUuid' => eventRecord.EventUuid,
                'EventCreationDateTime' => eventRecord.EventCreationDateTime,
                'EventPublishDateTime' => eventRecord.EventPublishDateTime,
                'EventSchemaVersion' => eventRecord.EventSchemaVersion,
                'EventPrompt' => eventRecord.EventPrompt,
                'ReplayId' => eventRecord.ReplayId,
                'ActionDeveloperName' => eventRecord.ActionDeveloperName,
                'SourceObjectDeveloperName' => eventRecord.SourceObjectDeveloperName,
                'ProfileIdValue' => eventRecord.ProfileIdValue,
                'TraceIdValue' => eventRecord.TraceIdValue,
                'Offset' => eventRecord.Offset
            };

            // Call LLM (CALLOUT - no DML here)
            EventProcessingResult llmResult = callLLMForSearchContext(eventRecord.PayloadCurrentValue, baseHeaders);
            llmResults.add(llmResult);
        }

        // ============================================================
        // PHASE 2: DML ONLY - All callouts are complete
        // ============================================================

        // Build Case updates and search context debug logs
        List<Case> casesToUpdate = new List<Case>();
        for (EventProcessingResult result : llmResults) {
            // Build Case update record
            Case caseUpdate = buildCaseUpdateWithClassification(result.caseId, result.response, result.eventTimestamp);
            if (caseUpdate != null) {
                casesToUpdate.add(caseUpdate);
            }

            // Build search context debug log record
            Debug_Log__c searchContextLog = buildSearchContextDebugLog(result);
            logsToInsert.add(searchContextLog);
        }

        // Bulk update Cases
        if (!casesToUpdate.isEmpty()) {
            List<Database.SaveResult> caseResults = Database.update(casesToUpdate, false);
            for (Integer i = 0; i < caseResults.size(); i++) {
                if (caseResults[i].isSuccess()) {
                    System.debug(LoggingLevel.INFO, 'Successfully updated Case: ' + casesToUpdate[i].Id);
                } else {
                    for (Database.Error err : caseResults[i].getErrors()) {
                        System.debug(LoggingLevel.ERROR, 'Error updating Case ' + casesToUpdate[i].Id + ': ' + err.getMessage());
                    }
                }
            }
        }

        // Bulk insert Debug_Log__c records
        if (!logsToInsert.isEmpty()) {
            Database.insert(logsToInsert, false);
        }
    }
}
