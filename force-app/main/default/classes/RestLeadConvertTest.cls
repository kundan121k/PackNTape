@isTest
public class RestLeadConvertTest{
    @TestSetup
    static void makeData(){
        insert new Lead(
            firstname = 'First',
            lastname = 'Last',
            company = 'Company'
        );
    }
    @isTest static void testNoBody() {
        Lead theLead = [SELECT Id FROM Lead LIMIT 1];
        RestContext.request = new RestRequest();
        RestContext.request.requestURI = '/leadconvert/' + theLead.Id;
        RestContext.request.httpMethod = 'POST';

        RestContext.response = new RestResponse();

        Test.startTest();
        RestLeadConvert.doPost();
        Test.stopTest();

        Lead convertedLead = [
            SELECT Id, ConvertedAccountId, ConvertedContactId, ConvertedOpportunityId, IsConverted
            FROM Lead
            WHERE Id = :theLead.Id
        ];
        system.assertEquals(True, convertedLead.IsConverted, 'Failed to convert lead');
    }

    @isTest static void testBadAccountId() {
        Lead theLead = [SELECT Id FROM Lead LIMIT 1];
        RestContext.request = new RestRequest();
        RestContext.request.requestURI = '/canonical-ua-shop/v1/leadconvert/' + theLead.Id;
        RestContext.request.httpMethod = 'POST';
        RestContext.request.requestBody = Blob.valueOf('{"accountId":"001D000001znOh8","convertedStatus":"Opportunity"}');

        RestContext.response = new RestResponse();

        Test.startTest();
        RestLeadConvert.doPost();
        Test.stopTest();

        system.assertEquals(RestLeadConvert.StatusCodeInternalServerError, RestContext.response.statusCode);
    }
    @isTest static void testBadJson() {
        Lead theLead = [SELECT Id FROM Lead LIMIT 1];
        RestContext.request = new RestRequest();
        RestContext.request.requestURI = '/canonical-ua-shop/v1/leadconvert/' + theLead.Id;
        RestContext.request.httpMethod = 'POST';
        RestContext.request.requestBody = Blob.valueOf('{"accountId":"001D00,"convertedStatus":"Opportunity"}');

        RestContext.response = new RestResponse();

        Test.startTest();
        RestLeadConvert.doPost();
        Test.stopTest();

        system.assertEquals(RestLeadConvert.StatusCodeBadRequest, RestContext.response.statusCode);
    }

    class TestCase {
        String requestURI;
        String expectedResult;
        String message;

        public TestCase(String requestURI, String expectedResult, String message) {
            this.requestURI = requestURI;
            this.expectedResult = expectedResult;
            this.message = message;
        }
    }

    @isTest static void testGetLeadId() {
        TestCase[] testCases = new List<TestCase> {
            new TestCase('', null, 'empty string should not be accepted as URI'),
            new TestCase('/', null, 'string with trailing slash should not be accepted as URI'),
            new TestCase('/00Q4K000001iiKjUAI', '00Q4K000001iiKjUAI', 'trailing 18 char lead id should be accepted as URI'),
            new TestCase('/00Q4K000001iiKj', '00Q4K000001iiKj', 'trailing 15 char lead id should be accepted as URI'),
            new TestCase('/00Q4K000001iiKjUA', null, 'trailing 17 char id should not be accepted as URI'),
            new TestCase('/0014K000001iiKjUAI', null, 'trailing account id should not be accepted as URI')
        };

        for (TestCase c : testCases) {
            system.assertEquals(c.expectedResult, RestLeadConvert.getTrailingLeadId(c.requestURI), c.message);
        }
    }
}