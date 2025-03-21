public class QuickbooksIntController {

    @AuraEnabled

    public static Boolean saveKeyAndSecret(String clientId, String clientSecret){

        try {

            List<QuickBooks_Integration__c> quickInfo = new List<QuickBooks_Integration__c>();

            quickInfo = [Select Id,ConsumerKey__c,ConsumerSecret__c FROM QuickBooks_Integration__c Where Name = 'QuickInfo' LIMIT 1];

            if(quickInfo != null && quickInfo.size() > 0){

                quickInfo[0].ConsumerKey__c=clientId;

                quickInfo[0].ConsumerSecret__c=clientSecret;

                update quickInfo;

            }

            else{

                QuickBooks_Integration__c linfo=new QuickBooks_Integration__c();

                linfo.Name = 'QuickInfo';

                linfo.ConsumerKey__c=clientId;

                linfo.ConsumerSecret__c=clientSecret;

                quickInfo.add(linfo);

                insert quickInfo;

            }

            return true;

        } catch (Exception e) {

            throw new AuraHandledException(e.getMessage());

        }

    }

    @AuraEnabled

    public static Boolean getAuthDone(String redirect_URI, String authCodeFromURL){
			System.debug('redirect_URI::' + redirect_URI);
			System.debug('authCodeFromURL::' + authCodeFromURL);
        try {

            String accessToken_Endpoint = 'https://oauth.platform.intuit.com/oauth2/v1/tokens/bearer?';

            List<QuickBooks_Integration__c> quickInfoList = new List<QuickBooks_Integration__c>();

            quickInfoList = [Select Id, Name,Access_Token__c,Expires_In_Seconds__c, ConsumerKey__c,ConsumerSecret__c FROM QuickBooks_Integration__c Where Name='QuickInfo'];

            System.debug(quickInfoList);

            // String authCodeFromURL = ApexPages.currentPage().getParameters().get('code');

            System.debug(authCodeFromURL);

                Http http = new Http();

                HttpRequest httpReq = new HttpRequest();

                HttpResponse httpRes = new HttpResponse();

                String requestTokenBody = 'code='+authCodeFromURL+'&grant_type=authorization_code'+

                                            '&client_id='+quickInfoList[0].ConsumerKey__c+'&client_secret='+quickInfoList[0].ConsumerSecret__c+

                                            '&redirect_uri='+redirect_URI;

                System.debug('#### authCodeFromURL '+authCodeFromURL);

                System.debug('#### requestTokenBody '+requestTokenBody);

                httpReq.setMethod('POST');

                httpReq.setEndpoint(accessToken_Endpoint);

                httpReq.setHeader('Content-Type', 'application/x-www-form-urlencoded');

                httpReq.setBody(requestTokenBody);

                    httpRes = http.send(httpReq);

                    System.debug('httpRes.getStatusCode()' + httpRes.getStatusCode());

                    if(httpRes.getStatusCode() == 200){

                        Map<String,object> TokenInfo = (Map<String,object>)JSON.deserializeUntyped(httpRes.getBody());

                        QuickBooks_Integration__c linkedlnInfo = new QuickBooks_Integration__c();

                        linkedlnInfo.Access_Token__c =  String.valueOf(TokenInfo.get('access_token'));

                        linkedlnInfo.Expires_In_Seconds__c =  Double.valueOf(TokenInfo.get('expires_in'));

                        linkedlnInfo.Name ='JiraInfo';

                        if(quickInfoList!=null && quickInfoList.size() > 0){

                            linkedlnInfo.Id = quickInfoList[0].Id;

                        }

                        upsert linkedlnInfo;

                        return true;

                    }else{

                        return false;

                    }

        }

         catch (Exception e) {

            throw new AuraHandledException(e.getMessage());

        }

    }

}