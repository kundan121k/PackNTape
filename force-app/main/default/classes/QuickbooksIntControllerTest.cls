@isTest
public class QuickbooksIntControllerTest {
    @testSetup
    static void setupTestData() {
        QuickBooks_Integration__c quickInfo = new QuickBooks_Integration__c(
            Name = 'QuickInfo',
            ConsumerKey__c = 'testClientId',
            ConsumerSecret__c = 'testClientSecret'
        );
        insert quickInfo;
    }

    @isTest
    static void testSaveKeyAndSecret_UpdateExistingRecord() {
        Test.startTest();
        Boolean result = QuickbooksIntController.saveKeyAndSecret('newClientId', 'newClientSecret');
        Test.stopTest();
        
        System.assert(result, 'Expected saveKeyAndSecret to return true');
        QuickBooks_Integration__c updatedRecord = [SELECT ConsumerKey__c, ConsumerSecret__c FROM QuickBooks_Integration__c WHERE Name = 'QuickInfo' LIMIT 1];
        System.assertEquals('newClientId', updatedRecord.ConsumerKey__c, 'ConsumerKey__c did not update correctly');
        System.assertEquals('newClientSecret', updatedRecord.ConsumerSecret__c, 'ConsumerSecret__c did not update correctly');
    }

    @isTest
    static void testSaveKeyAndSecret_InsertNewRecord() {
        delete [SELECT Id FROM QuickBooks_Integration__c WHERE Name = 'QuickInfo'];
        
        Test.startTest();
        Boolean result = QuickbooksIntController.saveKeyAndSecret('insertClientId', 'insertClientSecret');
        Test.stopTest();
        
        System.assert(result, 'Expected saveKeyAndSecret to return true');
        QuickBooks_Integration__c newRecord = [SELECT ConsumerKey__c, ConsumerSecret__c FROM QuickBooks_Integration__c WHERE Name = 'QuickInfo' LIMIT 1];
        System.assertEquals('insertClientId', newRecord.ConsumerKey__c, 'ConsumerKey__c did not insert correctly');
        System.assertEquals('insertClientSecret', newRecord.ConsumerSecret__c, 'ConsumerSecret__c did not insert correctly');
    }

    @isTest
    static void testGetAuthDone() {
        Test.startTest();
        
        Test.setMock(HttpCalloutMock.class, new MockHttpResponse(200, '{"access_token":"testAccessToken","expires_in":3600}'));
        
        Boolean result = QuickbooksIntController.getAuthDone('https://test.redirect.uri', 'testAuthCode');
        
        Test.stopTest();
        
        System.assert(result, 'Expected getAuthDone to return true');
        QuickBooks_Integration__c updatedRecord = [SELECT Access_Token__c, Expires_In_Seconds__c FROM QuickBooks_Integration__c WHERE Name = 'JiraInfo' LIMIT 1];
        System.assertEquals('testAccessToken', updatedRecord.Access_Token__c, 'Access_Token__c did not update correctly');
        System.assertEquals(3600.0, updatedRecord.Expires_In_Seconds__c, 'Expires_In_Seconds__c did not update correctly');
    }

    private class MockHttpResponse implements HttpCalloutMock {
        private Integer statusCode;
        private String responseBody;
        
        public MockHttpResponse(Integer code, String body) {
            this.statusCode = code;
            this.responseBody = body;
        }
        
        public HTTPResponse respond(HTTPRequest req) {
            HttpResponse res = new HttpResponse();
            res.setStatusCode(statusCode);
            res.setBody(responseBody);
            return res;
        }
    }
}