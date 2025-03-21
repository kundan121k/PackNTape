@isTest
public class TokenRefreshQueueableMock implements HttpCalloutMock {
    private Integer statusCode;
    private String responseBody;

    // Constructor to initialize the mock with a status code and response body
    public TokenRefreshQueueableMock(Integer statusCode, String responseBody) {
        this.statusCode = statusCode;
        this.responseBody = responseBody;
    }

    // Respond method implementation
    public HttpResponse respond(HttpRequest req) {
        HttpResponse response = new HttpResponse();
        response.setStatusCode(statusCode);
        response.setBody(responseBody);
        return response;
    }

    // Factory method for success case
    public static TokenRefreshQueueableMock successMock() {
        String body = '{"access_token": "newAccessToken", "refresh_token": "newRefreshToken"}';
        return new TokenRefreshQueueableMock(200, body);
    }

    // Factory method for failure case
    public static TokenRefreshQueueableMock failureMock() {
        String body = '{"error": "invalid_request"}';
        return new TokenRefreshQueueableMock(400, body);
    }
}