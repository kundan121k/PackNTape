@isTest
public class QuickBooksAuthSchedulerTest {

    @isTest static void testSchedulerExecution() {
        Test.startTest();
   
        String cronExp = '0 0 12 * * ?'; 
        
        String jobName = 'QuickBooksAuthJob';
        System.schedule(jobName, cronExp, new QuickBooksAuthScheduler());
        
        CronTrigger[] jobs = [SELECT Id, CronExpression FROM CronTrigger WHERE CronJobDetail.Name = :jobName];
        System.assertEquals(1, jobs.size(), 'There should be one scheduled job');
        System.assertEquals(cronExp, jobs[0].CronExpression, 'The cron expression should match');
		Test.stopTest();

    }
}