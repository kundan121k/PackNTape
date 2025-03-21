@RestResource(urlMapping='/api/casesealer')
global without sharing class CaseSealerToSF_WebhookHandler {
    @HttpPost
    global static void getCaseSealerData() {
        RestRequest req = RestContext.request;
        try {
            System.debug('### Received Webhook Data: ' + req.params);

            // Extracting required fields
            String firstName = req.params.get('Name');
            String lastName = req.params.get('LastName');
            String email = req.params.get('email');
            String company = req.params.get('company');
            String phone = req.params.get('phone');
            String location = req.params.get('location');
            String lookingFor = req.params.get('lookingfor');
            String dateCreated = req.params.get('date_created');
            String field1 = req.params.get('field1');
            String field2 = req.params.get('field2');

            if (String.isBlank(lastName)) {
                lastName = 'Unknown';
            }
            if (String.isBlank(firstName)) {
                firstName = 'User';
            }
            if (String.isBlank(company)) {
                company = 'Webhook Inquiry';
            }
            if(String.isBlank(phone)){
                phone = '';
            }

            // Constructing Lead description
            String description = 'Looking for: ' + lookingFor + ', Location: ' + location +
                                 ', Created on: ' + dateCreated + ', Extra Info: ' + field1 + ', ' + field2;

            Lead newLead = new Lead(
                FirstName = firstName,
                LastName = lastName,
                Email = email,
                Phone = phone,
                Company = company,
                Description = description,
                Status = 'Open - Not Contacted'
            );

            insert newLead;
            System.debug('### Lead Created Successfully: ' + newLead.Id);

        } catch (Exception e) {
            System.debug('### Webhook Processing Error: ' + e.getMessage());
        }
    }
}