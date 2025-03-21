@isTest
public class QuickBooksAuthControllerTest {

    @testSetup
    static void setupTestData() {
        // Insert test data for QuickBooks_Integration__c object
        QuickBooks_Integration__c quickInfo = new QuickBooks_Integration__c();
        quickInfo.Name = 'QuickInfo';
        quickInfo.ConsumerKey__c = 'testClientID';
        quickInfo.ConsumerSecret__c = 'testClientSecret';
        insert quickInfo;
    }

    @isTest
    static void testCompleteAuthSuccess() {
        Test.startTest();

        // Mock HTTP response for successful authentication
        HttpCalloutMock mockResponse = new QuickBooksMockHttpResponse(200, '{"access_token":"newAccessToken","expires_in":3600}');
        Test.setMock(HttpCalloutMock.class, mockResponse);

        // Set up a Visualforce page context to simulate the callback with parameters
        PageReference pageRef = Page.QuickbooksAuthPage; // Update page name here
        Test.setCurrentPage(pageRef);
        ApexPages.currentPage().getParameters().put('code', 'testAuthCode');
        ApexPages.currentPage().getParameters().put('redirect_uri', 'https://your-redirect-uri.com');

        // Instantiate the controller
        QuickBooksAuthController controller = new QuickBooksAuthController();

        // Invoke the completeAuth method
        controller.completeAuth();

        // Verify the result
        System.assertEquals('Successfully authenticated with QuickBooks!', controller.authStatus);
        System.assertEquals(false, controller.notAuth);

        // Check that the QuickBooks_Integration__c record has been updated
        QuickBooks_Integration__c updatedQuickInfo = [SELECT Access_Token__c FROM QuickBooks_Integration__c WHERE Name = 'QuickInfo' LIMIT 1];
        System.assertEquals('newAccessToken', updatedQuickInfo.Access_Token__c);

        Test.stopTest();
    }

    @isTest
    static void testCompleteAuthFailure() {
        Test.startTest();

        // Mock HTTP response for failed authentication
        HttpCalloutMock mockResponse = new QuickBooksMockHttpResponse(400, '{"error":"invalid_grant"}');
        Test.setMock(HttpCalloutMock.class, mockResponse);

        // Set up a Visualforce page context to simulate the callback with parameters
        PageReference pageRef = Page.QuickbooksAuthPage; // Update page name here
        Test.setCurrentPage(pageRef);
        ApexPages.currentPage().getParameters().put('code', 'testAuthCode');
        ApexPages.currentPage().getParameters().put('redirect_uri', 'https://your-redirect-uri.com');

        // Instantiate the controller
        QuickBooksAuthController controller = new QuickBooksAuthController();

        // Invoke the completeAuth method
        controller.completeAuth();

        // Verify the result
        System.assertEquals('Failed to authenticate.', controller.authStatus);
        System.assertEquals(true, controller.notAuth);

        Test.stopTest();
    }

    @isTest
    static void testPerformScheduledAuth() {
        Test.startTest();

        // Mock HTTP response for successful re-authentication
        HttpCalloutMock mockResponse = new QuickBooksMockHttpResponse(200, '{"access_token":"refreshedAccessToken","expires_in":3600}');
        Test.setMock(HttpCalloutMock.class, mockResponse);

        // Call the performScheduledAuth method
        QuickBooksAuthController.performScheduledAuth();

        // Verify that the QuickBooks_Integration__c record was updated
        QuickBooks_Integration__c updatedQuickInfo = [SELECT Access_Token__c FROM QuickBooks_Integration__c WHERE Name = 'QuickInfo' LIMIT 1];
        System.assertEquals('refreshedAccessToken', updatedQuickInfo.Access_Token__c);

        Test.stopTest();
    }
}