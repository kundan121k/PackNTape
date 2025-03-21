@isTest
public class QuickBooksMockHttpResponse implements HttpCalloutMock {
    private Integer statusCode;
    private String responseBody;

    public QuickBooksMockHttpResponse(Integer statusCode, String responseBody) {
        this.statusCode = statusCode;
        this.responseBody = responseBody;
    }

    public HTTPResponse respond(HTTPRequest req) {
        HttpResponse res = new HttpResponse();
        res.setStatusCode(statusCode);
        res.setBody(responseBody);
        return res;
    }
}