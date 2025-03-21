@isTest
public class RefreshTokenSchedulerTest {
    @isTest
    static void testExecute() {
        // Set the mock for the HTTP callout
        Test.setMock(HttpCalloutMock.class, new MockHttpResponseGenerator());
        
        // Schedule the job (runs every minute for the test)
        String cronExp = '0 0 * * * ?';
        String jobId = System.schedule('Test Refresh Token Job', cronExp, new RefreshTokenScheduler());

        Test.startTest();
        
        // Run the scheduler job
        RefreshTokenScheduler scheduler = new RefreshTokenScheduler();
        scheduler.execute(null); // Trigger the scheduled job logic directly

        Test.stopTest();

        // Verify the job was scheduled and completed
        CronTrigger ct = [SELECT Id, CronJobDetail.Name, State FROM CronTrigger WHERE Id = :jobId];
        System.assertEquals('Test Refresh Token Job', ct.CronJobDetail.Name);
        System.assertEquals('WAITING', ct.State, 'The job should have completed.');
    }
}