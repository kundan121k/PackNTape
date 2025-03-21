@isTest
global class MockHttpCallout implements HttpCalloutMock {
    global HTTPResponse respond(HTTPRequest req) {
        // Create a fake response
        HttpResponse res = new HttpResponse();
        res.setHeader('Content-Type', 'application/json');
        res.setBody('{"access_token": "mockAccessToken", "token_type": "Bearer"}');
        res.setStatusCode(200);
        return res;
    }
}