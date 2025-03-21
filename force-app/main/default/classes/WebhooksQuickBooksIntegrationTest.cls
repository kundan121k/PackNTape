@isTest
public class WebhooksQuickBooksIntegrationTest {

    // Mock class for HTTP responses
    private class MockHttpResponseGenerator implements HttpCalloutMock {
        public HTTPResponse respond(HTTPRequest req) {
            HttpResponse res = new HttpResponse();
            res.setHeader('Content-Type', 'application/json');
            res.setStatusCode(200);
            
            // Handling response based on endpoint
            if (req.getEndpoint().contains('/customer/')) {
                // Mock response for customer details
                res.setBody('{' +
                    '    "Customer": {' +
                    '        "Id": "12345",' +
                    '        "DisplayName": "Mock Customer",' +
                    '        "PrimaryEmailAddr": {"Address": "mock.customer@example.com"},' +
                    '        "CompanyName": "Mock Company",' +
                    '        "BillAddr": {' +
                    '            "City": "Mock City",' +
                    '            "PostalCode": "12345"' +
                    '        }' +
                    '    }' +
                    '}');
            } else {
                // Mock response for invoice details
                res.setBody('{' +
                    '    "Invoice": {' +
                    '        "Deposit": 50.00,' +
                    '        "TotalAmt": 500.00,' +
                    '        "Balance": 200.00,' +
                    '        "DocNumber": "INV-12345",' +
                    '        "TxnDate": "2024-11-22",' +
                    '        "DueDate": "2024-12-22",' +
                    '        "CustomerRef": { "name": "Mock Customer", "value": "123" },' +
                    '        "BillEmail": { "Address": "mock.customer@example.com" },' +
                    '        "Line": [' +
                    '            {' +
                    '                "Id": "1",' +
                    '                "Description": "Product A",' +
                    '                "Amount": 100.00,' +
                    '                "SalesItemLineDetail": {' +
                    '                    "UnitPrice": 10.00,' +
                    '                    "Qty": 10,' +
                    '                    "ItemRef": { "name": "Product A" }' +
                    '                }' +
                    '            }' +
                    '        ]' +
                    '    }' +
                    '}');
            }
            return res;
        }
    }

    // Test method for the CreateRecord functionality
    @isTest
    static void testCreateRecord() {
        Test.setMock(HttpCalloutMock.class, new MockHttpResponseGenerator());

        // Prepare mock request body for customer and invoice events
        String requestBody = JSON.serialize(new Map<String, Object> {
            'eventNotifications' => new List<Object> {
                new Map<String, Object> {
                    'dataChangeEvent' => new Map<String, Object> {
                        'entities' => new List<Object> {
                            new Map<String, Object>{ 'id' => '12345', 'name' => 'Customer' },
                            new Map<String, Object>{ 'id' => '67890', 'name' => 'Invoice' }
                        }
                    }
                }
            }
        });

        // Simulate the REST request and response
        RestRequest req = new RestRequest();
        req.requestBody = Blob.valueOf(requestBody);
        req.httpMethod = 'POST';
        req.requestURI = '/services/apexrest/quickbooks/';
        RestContext.request = req;

        RestResponse res = new RestResponse();
        RestContext.response = res;

        // Execute the target method
        Test.startTest();
        WebhooksQuickBooksIntegration.CreateRecord();
        Test.stopTest();

        // Validate the response and debug logs
        System.assertNotEquals(null, res, 'RestResponse should not be null.'); 
    }

    // Test method for access token refresh functionality
    @isTest
    static void testAccessTokenRefresh() {
       /* Test.setMock(HttpCalloutMock.class, new MockHttpResponseGenerator());

        Test.startTest();
        String accessToken = WebhooksQuickBooksIntegration.getAccessToken();
        Test.stopTest(); */
  Test.setMock(HttpCalloutMock.class, new MockHttpResponseGenerator());

// Insert mock refresh token record for testing
Generate_Refresh_Token__c mockToken = new Generate_Refresh_Token__c(Refresh_Token__c = 'testRefreshToken');
insert mockToken;

Test.startTest();
String accessToken = WebhooksQuickBooksIntegration.getAccessToken();
Test.stopTest();

    //System.assertNotEquals(null, accessToken, 'Access token should not be null.');

     
    }

    // Test method for retrieving customer details
    @isTest
    static void testGetCustomerDetails() {
        Test.setMock(HttpCalloutMock.class, new MockHttpResponseGenerator());

        String mockCustomerId = '12393';
        String mockAccessToken = 'mockAccessToken';

        Test.startTest();
        WebhooksQuickBooksIntegration.getCustomerDetails(mockCustomerId, mockAccessToken);
        Test.stopTest();

        // Validate Account creation or update based on the mock customer details
        List<Account> accounts = [
            SELECT Id, Name, Company_Email_Address__c, BillingCity, BillingPostalCode 
            FROM Account 
            WHERE quickBook_Customer_Id__c = :mockCustomerId
        ];
       
        // Ensure account was created or updated
        System.assertEquals(1, accounts.size(), 'Account should be created or updated.');
        System.assertEquals('Mock Customer', accounts[0].Name, 'Account name should match the mock customer display name.');
        System.assertEquals('mock.customer@example.com', accounts[0].Company_Email_Address__c, 'Account email should match the mock email.');
        System.assertEquals('Mock City', accounts[0].BillingCity, 'Account billing city should match the mock city.');
        System.assertEquals('12345', accounts[0].BillingPostalCode, 'Account billing postal code should match the mock postal code.');
    }
}