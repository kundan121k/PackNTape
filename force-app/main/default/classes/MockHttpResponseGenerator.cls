@isTest
public class MockHttpResponseGenerator implements HttpCalloutMock {
    public HttpResponse respond(HttpRequest req) {
        HttpResponse response = new HttpResponse();
        if (req.getEndpoint().contains('oauth.platform.intuit.com')) {
            response.setStatusCode(200);
            response.setBody('{"access_token": "mockAccessToken", "expires_in": 3600}');
        } else if (req.getEndpoint().contains('/v3/company/')) {
            response.setStatusCode(200);
            response.setBody('{"Customer": {"Id": "12393", "DisplayName": "Mock Customer", "PrimaryEmailAddr": {"Address": "mock@example.com"}, "CompanyName": "Mock Company", "BillAddr": {"City": "Mock City", "PostalCode": "12345"}}}');
        } else {
            response.setStatusCode(404);
            response.setBody('{"error": "Not Found"}');
        }
        
        response.setHeader('Content-Type', 'application/json');
        return response;
    }
}