/**
 * Queueable class to handle callouts and DML operations separately from the trigger context
 * to avoid "Can't perform callout because of pending uncommitted changes" errors.
 */
public with sharing class DataCloudDataChangeEventQueueable implements Queueable, Database.AllowsCallouts {
    
    private final List<DataObjectDataChgEvent> events;
    
    public DataCloudDataChangeEventQueueable(List<DataObjectDataChgEvent> events) {
        this.events = events;
    }
    
    public void execute(QueueableContext context) {
        DataCloudDataChangeEventController.processEvents(this.events);
    }
}
