global class RefreshTokenScheduler implements Schedulable {
    global void execute(SchedulableContext sc) {
        System.enqueueJob(new RefreshTokenQueueable());
    }
}