public class TokenRefreshQueueable implements Queueable, Database.AllowsCallouts {
    private static final String CLIENT_ID = Label.QuickBooks_Client_ID;
    private static final String CLIENT_SECRET = Label.QuickBooks_Client_Secret;
    private static final String TOKEN_ENDPOINT = 'https://oauth.platform.intuit.com/oauth2/v1/tokens/bearer';

    public void execute(QueueableContext context) {
        refreshAccessToken();
    }

    public static String refreshAccessToken() {
        try {
            Http http = new Http();
            HttpRequest request = new HttpRequest();
            request.setEndpoint(TOKEN_ENDPOINT);
            request.setMethod('POST');
            request.setHeader('Content-Type', 'application/x-www-form-urlencoded');

            // Construct the request body
            String body = 'grant_type=refresh_token'
                + '&refresh_token=' + EncodingUtil.urlEncode(getStoredRefreshToken(), 'UTF-8')
                + '&client_id=' + CLIENT_ID
                + '&client_secret=' + CLIENT_SECRET;
            request.setBody(body);

            // Send the request
            HttpResponse response = http.send(request);
            if (response.getStatusCode() == 200) {
                Map<String, Object> responseMap = (Map<String, Object>) JSON.deserializeUntyped(response.getBody());

                String newAccessToken = (String) responseMap.get('access_token');
                String newRefreshToken = (String) responseMap.get('refresh_token');

                // Store the new tokens securely
                storeTokens(newAccessToken, newRefreshToken);

                System.debug('Tokens refreshed successfully');
                return 'Tokens refreshed successfully';
            } else {
                System.debug('Failed to refresh tokens: ' + response.getBody());
                return 'Error: Failed to refresh tokens';
            }
        } catch (Exception e) {
            System.debug('Exception during token refresh: ' + e.getMessage());
            return 'Error: Exception occurred during token refresh: ' + e.getMessage();
        }
    }

    private static String getStoredRefreshToken() {
        try {
            // Query the custom setting to get the refresh token
            Generate_Refresh_Token__c customSetting = [
                SELECT Refresh_Token__c 
                FROM Generate_Refresh_Token__c 
               
                LIMIT 1
            ];
            
            // Ensure the result is not null and contains the refresh token
            if (customSetting != null && customSetting.Refresh_Token__c != null) {
                return customSetting.Refresh_Token__c;
            } else {
                System.debug('Error: Refresh token not found in custom setting.');
                return null; // Handle the case where no token is found
            }
        } catch (Exception e) {
            System.debug('Exception occurred while fetching refresh token: ' + e.getMessage());
            return null; // Handle the exception case
        }
    }

    private static void storeTokens(String accessToken, String refreshToken) {
        try {
            // Update the custom setting with the new refresh token
            Generate_Refresh_Token__c customSetting = [
                SELECT Id, Refresh_Token__c 
                FROM Generate_Refresh_Token__c 
               
                LIMIT 1
            ];

            if (customSetting != null) {
                customSetting.Refresh_Token__c = refreshToken;
                update customSetting;
                System.debug('Refresh token updated successfully in custom setting.');
            } else {
                System.debug('Error: Custom setting record not found.');
            }

            // Debug log for the new access token
            System.debug('New Access Token: ' + accessToken);
        } catch (Exception e) {
            System.debug('Exception occurred while storing tokens: ' + e.getMessage());
        }
    }
}