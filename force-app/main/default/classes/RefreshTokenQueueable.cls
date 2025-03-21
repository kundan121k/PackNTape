public class RefreshTokenQueueable implements Queueable, Database.AllowsCallouts {
    public void execute(QueueableContext context) {
        WebhooksQuickBooksIntegration.getAccessToken();
    }
}