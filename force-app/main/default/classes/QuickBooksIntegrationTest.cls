@isTest
public class QuickBooksIntegrationTest {
    @isTest
    static void testCreateRecord() {
        // Set mock HTTP responses using the provided MockHttpResponseGenerator class
        Test.setMock(HttpCalloutMock.class, new MockHttpResponseGenerator());

        // Simulate the request payload received by the CreateRecord method
        String mockPayload = '{"eventNotifications": [' +
                             '  {' +
                             '    "dataChangeEvent": {' +
                             '      "entities": [' +
                             '        {"id": "12345", "name": "Customer"},' +
                             '        {"id": "67890", "name": "Invoice"}' +
                             '      ]' +
                             '    }' +
                             '  }' +
                             ']}';

        // Set up the mock request
        RestRequest req = new RestRequest();
        req.requestBody = Blob.valueOf(mockPayload);
        req.httpMethod = 'POST';
        RestContext.request = req;

        // Set up a mock response
        RestResponse res = new RestResponse();
        RestContext.response = res;

        Test.startTest();
        WebhooksQuickBooksIntegration.CreateRecord();
        Test.stopTest();

        // Assertions or debug logs to verify the functionality
        //System.assertEquals(200, RestContext.response.statusCode, 'Response status should be 200');
    }

    @isTest
    static void testGetAccessToken() {
        // Set mock HTTP responses using the provided MockHttpResponseGenerator class
        Test.setMock(HttpCalloutMock.class, new MockHttpResponseGenerator());

        Test.startTest();
        String accessToken = WebhooksQuickBooksIntegration.getAccessToken();
        Test.stopTest();

        // Assertions
        System.assertEquals('mockAccessToken', accessToken, 'Access token should match the mock response');
    }

    @isTest
    static void testGetCustomerDetails() {
        // Set mock HTTP responses using the provided MockHttpResponseGenerator class
        Test.setMock(HttpCalloutMock.class, new MockHttpResponseGenerator());

        Test.startTest();
        WebhooksQuickBooksIntegration.getCustomerDetails('12345', 'mockAccessToken');
        Test.stopTest();

        // Verify through debug logs or by asserting dependent operations
        System.debug('Customer details successfully retrieved.');
    }

    @isTest
    static void testGetInvoiceDetails() {
        // Set mock HTTP responses using the provided MockHttpResponseGenerator class
        Test.setMock(HttpCalloutMock.class, new MockHttpResponseGenerator());

        Test.startTest();
        WebhooksQuickBooksIntegration.getInvoiceDetails('67890', 'mockAccessToken');
        Test.stopTest();

        // Verify through debug logs or by asserting dependent operations
        System.debug('Invoice details successfully retrieved.');
    }
}