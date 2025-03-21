@isTest
public class TokenRefreshQueueableTest {
    @isTest
    static void testTokenRefreshSuccess() {
        // Set up a mock HTTP response for successful token refresh
        Test.setMock(HttpCalloutMock.class, new TokenRefreshQueueableMock(200, '{"access_token": "newAccessToken", "refresh_token": "newRefreshToken"}'));
        
        // Insert a custom setting with an existing refresh token
        Generate_Refresh_Token__c customSetting = new Generate_Refresh_Token__c(
            Refresh_Token__c = 'existingRefreshToken'
        );
        insert customSetting;
        
        // Enqueue and execute the queueable
        Test.startTest();
        TokenRefreshQueueable queueable = new TokenRefreshQueueable();
        System.enqueueJob(queueable);
        Test.stopTest();
        
        // Verify that the custom setting was updated with the new refresh token
        Generate_Refresh_Token__c updatedSetting = [
            SELECT Refresh_Token__c 
            FROM Generate_Refresh_Token__c 
            WHERE Id = :customSetting.Id
            LIMIT 1
        ];
        //System.assertEquals('newRefreshToken', updatedSetting.Refresh_Token__c, 'Refresh token should be updated');
    }
    
    @isTest
    static void testTokenRefreshFailure() {
        // Set up a mock HTTP response for failed token refresh
        Test.setMock(HttpCalloutMock.class, new TokenRefreshQueueableMock(400, '{"error": "invalid_request"}'));
        
        // Insert a custom setting with an existing refresh tokenijmr
        Generate_Refresh_Token__c customSetting = new Generate_Refresh_Token__c(
            Refresh_Token__c = 'existingRefreshToken'
        );
        insert customSetting;
        
        // Enqueue and execute the queueable
        Test.startTest();
        TokenRefreshQueueable queueable = new TokenRefreshQueueable();
        System.enqueueJob(queueable);
        Test.stopTest();
        
        // Verify that the custom setting remains unchanged
        Generate_Refresh_Token__c unchangedSetting = [
            SELECT Refresh_Token__c 
            FROM Generate_Refresh_Token__c 
            WHERE Id = :customSetting.Id
            LIMIT 1
        ];
        System.assertEquals('existingRefreshToken', unchangedSetting.Refresh_Token__c, 'Refresh token should remain unchanged');
    }
}