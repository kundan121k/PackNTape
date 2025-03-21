/* 
    RestLeadConvert

    Provides a REST endpoint that exposes the Lead Conversion feature of Apex.

    If request body is omitted, convertedStatus is set to 'Opportunity' and all other fields to null

    Request body content is json as follows. All name/value pairs (except convertedStatus) are optional

   {
      "accountId":null,
      "accountRecord":null,
      "bypassAccountDedupeCheck":null,
      "bypassContactDedupeCheck":null,
      "contactId":null,
      "contactRecord":null,
      "convertedStatus":null,
      "doNotCreateOpportunity":false,
      "leadId":null,
      "opportunityId":null,
      "opportunityName":null,
      "opportunityRecord":null,
      "overwriteLeadSource":false,
      "ownerId":null,
      "relatedPersonAccountId":null,
      "relatedPersonAccountRecord":null,
      "sendNotificationEmail":false
    }

    The meanings of all these parameters are documented in Apex Developer Guide, see class Database.LeadConvert

    Response body contains a Database.LeadConvertResult, also documented in Apex Developer Guide.

    url: '<baseurl>/services/apexrest/leadconvert/<leadid>'

*/

@RestResource(urlMapping='/leadconvert/*')
global with sharing class RestLeadConvert {
    public static final Integer StatusCodeOK = 200;
    public static final Integer StatusCodeBadRequest = 400;
    public static final Integer StatusCodeInternalServerError = 500;
    public static String DEFAULT_CONVERTED_STATUS = [SELECT Id, MasterLabel FROM LeadStatus WHERE IsConverted=true limit 1].MasterLabel;

    public class BadRequestException extends Exception {}

    // Represents a REST response
    class ResponseObject {
        String message;
        String code;
        Database.LeadConvertResult lead_convert_result;

        public Blob blob() {
            return Blob.valueOf(JSON.serialize(this));
        }

        public ResponseObject(String message, String code, Database.LeadConvertResult lcr) {
            this(message, code);
            this.lead_convert_result = lcr;
        }

        public ResponseObject(String message, String code) {
            this.message = message;
            this.code = code;
        }
    }

    @HttpPost
    global static void doPost() {
        RestContext.response.addHeader('Content-Type', 'application/json');

        Database.LeadConvertResult lcr ;
        try {
            Database.LeadConvert lc = parseRequest(RestContext.request);
            lc.setLeadId(parseTrailingLeadId(RestContext.request.requestURI));

            lcr = Database.convertLead(lc);
        }
        catch (Exception e) {
            RestContext.response.responseBody = new ResponseObject(e.getMessage(), exceptionTypeNameToCode(e)).blob();

            if (e.getTypeName() == 'RestLeadConvert.BadRequestException') {
                RestContext.response.statusCode = StatusCodeBadRequest;
            }
            else {
                // any other exception is unexpected; dump the exception and a stack trace to help debug it in production
                system.debug(e);
                system.debug(e.getStackTraceString());
                RestContext.response.statusCode = StatusCodeInternalServerError;
            }
            return;
        }
    
        if (lcr.isSuccess()) {
            RestContext.response.responseBody = new ResponseObject('Success', 'success', lcr).blob();
            RestContext.response.statusCode = StatusCodeOK;
        }
        else {
            RestContext.response.responseBody = new ResponseObject('Fail', 'see lead_convert_result', lcr).blob();
            RestContext.response.statusCode = StatusCodeInternalServerError;
        }
    }

    // Given an Exception typename like 'RestLeadConvert.BadRequestException', return 'BadRequestException'
    static String exceptionTypeNameToCode(Exception e) {
        String[] qualifiedName = e.getTypeName().split('\\.');
        return qualifiedName[qualifiedName.size()-1];
    }
    
    // completely parse the request body into an instance of LeadConvertBody
    // throw exception if it fails to parse in any way
    @TestVisible static Database.LeadConvert parseRequest(RestRequest request) {
        if (request.requestBody == null) {
            return createDefaultLeadConvert();
        }

        try {
            return (Database.LeadConvert)JSON.deserialize(request.requestBody.toString(), Database.LeadConvert.class);
        }
        catch(Exception e) {
            throw new BadRequestException('Failed to deserialize json body (%)'.replace('%', e.getMessage()));
        }
    }

    // this determines the behavior for a POST with no request body
    static Database.LeadConvert createDefaultLeadConvert() {
        Database.LeadConvert lc = new Database.LeadConvert(); 
        lc.setConvertedStatus(DEFAULT_CONVERTED_STATUS);
        return lc;
    }

    // get the LeadId from the requestURI and throw an exception if impossible
    static Id parseTrailingLeadId(String requestURI) {
        String leadId = getTrailingLeadId(requestURI);
        if (leadId == null) {
            throw new BadRequestException('requestURI does not have a valid trailing Lead Id');
        }
        return leadId;
    }

    // get the LeadId from the requestURI and return null if impossible
    @TestVisible
    static Id getTrailingLeadId(String requestURI) {
        Integer lastSlashIndex = requestURI.lastIndexOf('/');
        if (lastSlashIndex != -1) {
            String leadId = requestURI.substring(lastSlashIndex+1);
            if (leadId instanceOf Id && ((ID)leadId).getsobjecttype() == Schema.Lead.getSObjectType()) {
                return (Id)leadId;
            }
        }

        return null;
    }
}