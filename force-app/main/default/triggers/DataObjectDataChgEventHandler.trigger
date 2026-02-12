trigger DataObjectDataChgEventHandler on DataObjectDataChgEvent (after insert) {
    System.debug(LoggingLevel.DEBUG, 'DataObjectDataChgEventHandler triggered with event: ' + JSON.serializePretty(Trigger.new));
    // Enqueue the processing in a separate transaction to avoid callout errors
    System.enqueueJob(new DataCloudDataChangeEventQueueable(Trigger.new));
}
