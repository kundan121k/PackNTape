public class QuickBooksWebhookValidator {
    
    // Name of the header that contains the signature
    private static final String SIGNATURE_HEADER = 'intuit-signature';
    
    // HMAC-SHA256 algorithm identifier
    private static final String ALGORITHM = 'HMACSHA256';

    /**
     * This method verifies the webhook signature using HMAC-SHA256
     * @param headers - HTTP request headers (should include 'intuit-signature')
     * @param payload - The request body (JSON payload) sent by QuickBooks
     * @param verifier - The secret key to validate the signature
     * @return Boolean indicating if the request is valid or not
     */
    public static Boolean isRequestValid(Map<String, String> headers, String payload, String verifier) {
        // Get the signature from the headers
        String signature = headers.get(SIGNATURE_HEADER);
        
        if (signature == null) {
            System.debug('Signature is missing from headers.');
            return false;
        }

        try {
            // Generate the HMAC-SHA256 hash of the payload using the verifier as the secret key
            Blob secretKey = Blob.valueOf(verifier);
            Blob payloadBlob = Blob.valueOf(payload);
            
            // Generate the HMACSHA256 hash
            Blob mac = Crypto.generateMac(ALGORITHM, payloadBlob, secretKey);
            
            // Base64 encode the result
            String hash = EncodingUtil.base64Encode(mac);
            
            // Compare the generated hash with the signature from the request headers
            return hash == signature;
        } catch (Exception e) {
            System.debug('Error while validating signature: ' + e.getMessage());
            return false;
        }
    }
}