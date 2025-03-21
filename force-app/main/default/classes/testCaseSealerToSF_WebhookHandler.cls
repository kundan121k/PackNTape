@isTest
private class testCaseSealerToSF_WebhookHandler {
    
    // Helper method to create mock request
    private static void mockRestRequest(Map<String, String> params) {
        RestRequest req = new RestRequest();
        req.httpMethod = 'POST';
        req.requestURI = '/services/apexrest/webhook/receive';

        for (String key : params.keySet()) {
            req.addParameter(key, params.get(key));
        }

        RestContext.request = req;
        RestContext.response = new RestResponse();
    }

    private static Lead getLeadByEmail(String email) {
        List<Lead> leads = [SELECT FirstName, LastName, Email, Company, Description, Status FROM Lead WHERE Email = :email];
        System.assertEquals(1, leads.size(), 'Lead should be created.');
        return leads[0];
    }

    @isTest
    static void testWebhookProcessing() {
        Test.startTest();

        Map<String, String> params = new Map<String, String>{
            'Name' => 'John',
            'LastName' => 'Doe',
            'email' => 'john.doe@example.com',
            'company' => 'Tech Corp',
            'location' => 'San Francisco',
            'lookingfor' => 'CRM Solutions',
            'date_created' => '2024-03-15',
            'field1' => 'Extra Info 1',
            'field2' => 'Extra Info 2'
        };
        mockRestRequest(params);
        CaseSealerToSF_WebhookHandler.getCaseSealerData();

        Test.stopTest();
        Lead lead = getLeadByEmail('john.doe@example.com');
        System.assertEquals('John', lead.FirstName);
        System.assertEquals('Doe', lead.LastName);
        System.assertEquals('Tech Corp', lead.Company);
        System.assertEquals('Open - Not Contacted', lead.Status);
        System.assert(lead.Description.contains('Looking for: CRM Solutions'));
        System.assert(lead.Description.contains('Location: San Francisco'));
        System.assert(lead.Description.contains('Created on: 2024-03-15'));
        System.assert(lead.Description.contains('Extra Info 1'));
        System.assert(lead.Description.contains('Extra Info 2'));
    }

    @isTest
    static void testWebhookProcessingWithMissingFields() {
        Test.startTest();
        Map<String, String> params = new Map<String, String>{
            'email' => 'jane.doe@example.com'
        };
        mockRestRequest(params);
        CaseSealerToSF_WebhookHandler.getCaseSealerData();

        Test.stopTest();

        Lead lead = getLeadByEmail('jane.doe@example.com');
        System.assertEquals('User', lead.FirstName);
        System.assertEquals('Unknown', lead.LastName);
        System.assertEquals('Webhook Inquiry', lead.Company);
        System.assert(lead.Description.contains('Looking for: null'));
        System.assert(lead.Description.contains('Location: null'));
        System.assert(lead.Description.contains('Created on: null'));
    }
}