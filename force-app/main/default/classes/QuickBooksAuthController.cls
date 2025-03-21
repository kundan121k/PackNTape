public class QuickBooksAuthController {
    public String authStatus { get; set; }
    public Boolean notAuth { get; set; }
    
    // Constructor to initialize default values
    public QuickBooksAuthController() {
        notAuth = true;  // Default to showing the authorization button
    }
    
    // Method to handle the OAuth authentication and get the access token
    public PageReference completeAuth() {
        String authCode = ApexPages.currentPage().getParameters().get('code');
        String redirectURI = ApexPages.currentPage().getParameters().get('redirect_uri');
        
        try {
            Boolean authSuccess = getAuthDone(redirectURI, authCode);
            if (authSuccess) {
                authStatus = 'Successfully authenticated with QuickBooks!';
                notAuth = false;
                // Save client ID and secret after successful authentication
                saveClientDetails();
            } else {
                authStatus = 'Failed to authenticate.';
            }
        } catch (Exception e) {
            authStatus = e.getMessage();
        }
        return null;
    }
    
    // Method to save client ID and secret to a custom object
    private void saveClientDetails() {
        try {
            QuickBooks_Integration__c quickInfo = new QuickBooks_Integration__c();
            quickInfo.ConsumerKey__c = Label.QuickBooks_Client_ID;  // Using Custom Label
            quickInfo.ConsumerSecret__c = Label.QuickBooks_Client_Secret;  // Using Custom Label
            insert quickInfo; // Save the new record
        } catch (Exception e) {
            authStatus = 'Error saving Client ID and Secret: ' + e.getMessage();
        }
    }
    
    
    
    
    // New static method to be called by the scheduled job
    @AuraEnabled
    public static void performScheduledAuth() {
        // Get the saved QuickBooks credentials from the custom object
        List<QuickBooks_Integration__c> quickInfoList = [SELECT Id, ConsumerKey__c, ConsumerSecret__c, Access_Token__c FROM QuickBooks_Integration__c WHERE Name = 'QuickInfo'];
        
        if (quickInfoList.size() > 0) {
            QuickBooks_Integration__c quickInfo = quickInfoList[0];
            
            // Use the existing token to get a new one or re-authenticate
            String redirectURI = 'https://your-redirect-uri.com'; // Update with your redirect URI
            String authCode = 'your-auth-code'; // Retrieve stored authorization code
            
            Boolean authSuccess = getAuthDone(redirectURI, authCode);
            
            if (authSuccess) {
                System.debug('QuickBooks re-authentication successful.');
            } else {
                System.debug('QuickBooks re-authentication failed.');
            }
        } else {
            System.debug('No QuickBooks integration info found.');
        }
    }
    
    // Method to exchange authorization code for access token
    @AuraEnabled
    public static Boolean getAuthDone(String redirect_URI, String authCodeFromURL) {
        try {
            String accessTokenEndpoint = 'https://oauth.platform.intuit.com/oauth2/v1/tokens/bearer';
            List<QuickBooks_Integration__c> quickInfoList = [SELECT Id, ConsumerKey__c, ConsumerSecret__c FROM QuickBooks_Integration__c WHERE Name = 'QuickInfo'];
            
            Http http = new Http();
            HttpRequest req = new HttpRequest();
            req.setEndpoint(accessTokenEndpoint);
            req.setMethod('POST');
            req.setHeader('Content-Type', 'application/x-www-form-urlencoded');
            
            // Use Custom Labels for Client ID and Secret
            String clientId = Label.QuickBooks_Client_ID;
            String clientSecret = Label.QuickBooks_Client_Secret;
            
            String requestBody = 'code=' + authCodeFromURL + 
                '&grant_type=authorization_code' +
                '&client_id=' + clientId + 
                '&client_secret=' + clientSecret + 
                '&redirect_uri=' + redirect_URI;
            req.setBody(requestBody);
            
            HttpResponse res = http.send(req);
            
            if (res.getStatusCode() == 200) {
                Map<String, Object> tokenInfo = (Map<String, Object>) JSON.deserializeUntyped(res.getBody());
                QuickBooks_Integration__c linkedInfo = new QuickBooks_Integration__c();
                linkedInfo.Access_Token__c = (String) tokenInfo.get('access_token');
                linkedInfo.Expires_In_Seconds__c = (Double) tokenInfo.get('expires_in');
                linkedInfo.Name = 'QuickInfo';
                
                // Update or insert the record
                if (quickInfoList != null && quickInfoList.size() > 0) {
                    linkedInfo.Id = quickInfoList[0].Id;
                    update linkedInfo;
                } else {
                    insert linkedInfo;
                }
                return true;
            }
            return false;
        } catch (Exception e) {
            throw new AuraHandledException(e.getMessage());
        }
    }
}