@isTest
public class TokenRefreshSchedulerTest {
    @isTest
    static void testTokenRefreshScheduler() {
        Test.startTest();
        
        // Schedule the job for a valid near-future time
        String cronExpression = '0 0 0 * * ?'; // Runs at midnight daily
        String jobId = System.schedule('Test Token Refresh Scheduler', cronExpression, new TokenRefreshScheduler());
        
        Test.stopTest();
        
        // Validate that the job was scheduled successfully
        System.assertNotEquals(null, jobId, 'The job ID should not be null');
    }
}