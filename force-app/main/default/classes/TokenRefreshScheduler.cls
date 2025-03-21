global class TokenRefreshScheduler implements Schedulable {
    global void execute(SchedulableContext sc) {
        // Enqueue the TokenRefreshQueueable class
        System.enqueueJob(new TokenRefreshQueueable());
    }
}