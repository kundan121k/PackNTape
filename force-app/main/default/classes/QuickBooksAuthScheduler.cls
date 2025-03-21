global class QuickBooksAuthScheduler implements Schedulable {

    global void execute(SchedulableContext sc) {
        QuickBooksAuthController.performScheduledAuth(); 
    }
}