@RestResource(urlMapping='/quickbooks/*')
global class WebhooksQuickBooksIntegration {
    private static  List<Generate_Refresh_Token__c> refreshToken = [SELECT Id, Refresh_Token__c, AccessToken__c  FROM Generate_Refresh_Token__c];
    private static Boolean isInvoiceAlreadyProcessed = false;
    @HttpPost
    global static void CreateRecord() {
        RestRequest request = RestContext.request;
        Blob body = request.requestBody;
        
        
        String bodyString = body.toString();
        // Debug the received body
        System.debug('Received body: ' + bodyString);
        // Parse the bodyString to a Map (deserializing JSON)
        try {
            Map<String, Object> payload = (Map<String, Object>) JSON.deserializeUntyped(bodyString);
            System.debug('Parsed payload: ' + payload);
            // Access eventNotifications (a list of maps)
            if (payload.containsKey('eventNotifications')) {
                List<Object> eventNotifications = (List<Object>) payload.get('eventNotifications');
                system.debug('eventNotifications:: '+eventNotifications);
                if (eventNotifications != null && !eventNotifications.isEmpty()) {
                    set<string> triggerEventCustomerIdSet = new set<string>();
                    set<string> triggerEventInvoiceIdSet = new set<string>();
                    for (Object eventNotificationObj : eventNotifications) {
                        Map<String, Object> eventNotification = (Map<String, Object>) eventNotificationObj;
                        system.debug('eventNotification:: '+eventNotification);
                        if (eventNotification.containsKey('dataChangeEvent')) {
                            Map<String, Object> dataChangeEvent = (Map<String, Object>) eventNotification.get('dataChangeEvent');
                            system.debug('dataChangeEvent:: '+dataChangeEvent);
                            if (dataChangeEvent.containsKey('entities')) {
                                List<Object> entities = (List<Object>) dataChangeEvent.get('entities');
                                system.debug('entities:: '+entities);
                                if (entities != null && !entities.isEmpty()) {
                                    for (Object entityObj : entities) {
                                        Map<String, Object> entity = (Map<String, Object>) entityObj;
                                        system.debug('entity:: '+entity);
                                        if (entity.containsKey('id')){
                                            if (entity.containsKey('name') && entity.get('name') == 'Customer') {
                                                System.debug('Entity is an Customer.');
                                                triggerEventCustomerIdSet.add((String)entity.get('id'));
                                            }else if (entity.containsKey('name') && entity.get('name') == 'Invoice') {
                                                System.debug('Entity is an Invoice.');
                                                
                                                getInvoiceDetails((String)entity.get('id'));
                                            }
                                        }
                                    }
                                }
                            }
                        }
                    }
                } 
            }
            
        } catch (Exception e) {
            System.debug('Error in deserializing the JSON: ' + e.getMessage());
        }
    } 
    
    private static final String CLIENT_ID = Label.QuickBooks_Client_ID;
    private static final String CLIENT_SECRET = Label.QuickBooks_Client_Secret;
    public static Map<String, String> getAccessToken() {
        
        Map<String, String> tokenMap = new Map<String, String>();
        try {
            Http http = new Http();
            HttpRequest request = new HttpRequest();
            request.setEndpoint('https://oauth.platform.intuit.com/oauth2/v1/tokens/bearer');
            request.setMethod('POST');
            request.setHeader('Content-Type', 'application/x-www-form-urlencoded');
            String body = 'grant_type=refresh_token'
                + '&refresh_token=' + refreshToken[0].Refresh_Token__c
                + '&client_id=' + CLIENT_ID
                + '&client_secret=' + CLIENT_SECRET;
            request.setBody(body);
            HttpResponse response = http.send(request);
            system.debug('status code :: '+response.getStatusCode());
            if (response.getStatusCode() == 200) {
                Map<String, Object> responseMap = (Map<String, Object>) JSON.deserializeUntyped(response.getBody());
                String accessToken = (String) responseMap.get('access_token');
                String newRefreshToken = (String) responseMap.get('refresh_token');
                tokenMap.put('access_token', accessToken);
                tokenMap.put('refresh_token', newRefreshToken);
                if (newRefreshToken != null) {
                    system.debug('newRefreshToken : '+newRefreshToken);
                    
                    //newToken=newRefreshToken;
                    //system.debug('newToken : '+newToken);
                    //FundraisingController.updateToken(newRefreshToken);
                    //updateRefreshToken(newRefreshToken);
                }
                return tokenMap;
            } else {
                System.debug('Failed to refresh access token: ' + response.getBody());
                throw new CalloutException('Failed to refresh access token');
            }
        } catch (Exception e) {
            throw new CalloutException('Exception in getAccessToken: ' + e.getMessage());
        }
    } 
    
    
    @future(callout=true)
    public static void getCustomerDetails(String customerId, String accessToken) {
        //String companyId = '9341453052826852';
        String companyId = Label.companyId;
        try {
            Http http = new Http();
            HttpRequest request = new HttpRequest();
            request.setEndpoint('https://sandbox-quickbooks.api.intuit.com/v3/company/' + companyId + '/customer/' + customerId);
            request.setMethod('GET');
            request.setHeader('Authorization', 'Bearer ' + accessToken);
            request.setHeader('Accept', 'application/json');
            HttpResponse response = http.send(request);
            // Check for a successful status code
            if (response.getStatusCode() == 200) {
                // Deserialize the response to a map
                Map<String, Object> responseMap = (Map<String, Object>) JSON.deserializeUntyped(response.getBody());
                System.debug('Customer details : ' + responseMap);
                
                // Ensure the 'Customer' field is present in the response
                if (responseMap.containsKey('Customer') && responseMap.get('Customer') instanceof Map<String, Object>) {
                    Map<String, Object> customer = (Map<String, Object>) responseMap.get('Customer');
                    
                    // Extract and debug specific fields (checking for null values)
                    String email = (customer.containsKey('PrimaryEmailAddr') && customer.get('PrimaryEmailAddr') instanceof Map<String, Object> && 
                                    ((Map<String, Object>)customer.get('PrimaryEmailAddr')).containsKey('Address')) ? 
                        (String) ((Map<String, Object>)customer.get('PrimaryEmailAddr')).get('Address') : '';
                    String displayName = (customer.containsKey('DisplayName') && customer.get('DisplayName') instanceof String) ? 
                        (String) customer.get('DisplayName') : '';
                    String companyName = (customer.containsKey('CompanyName') && customer.get('CompanyName') instanceof String) ? 
                        (String) customer.get('CompanyName') : '';
                    //createOrUpdateAccount(displayName, email);
                    System.debug('Customer Email: ' + email);
                    System.debug('Customer Display Name: ' + displayName);
                    System.debug('Customer Company Name: ' + companyName);
                    // Handle BillAddr fields (if present)
                    if (customer.containsKey('BillAddr') && customer.get('BillAddr') instanceof Map<String, Object>) {
                        Map<String, Object> billAddr = (Map<String, Object>) customer.get('BillAddr');
                        String city = (billAddr.containsKey('City') && billAddr.get('City') instanceof String) ? 
                            (String) billAddr.get('City') : 'N/A';
                        String postalCode = (billAddr.containsKey('PostalCode') && billAddr.get('PostalCode') instanceof String) ? 
                            (String) billAddr.get('PostalCode') : 'N/A';
                        // Pass all extracted values to createOrUpdateAccount method
                        createOrUpdateAccount(displayName, email, city, postalCode, companyName,customerId);
                        System.debug('Billing City: ' + city);
                        System.debug('Postal Code: ' + postalCode);
                    } else {
                        System.debug('No billing address found.');
                    }
                } 
                else {
                    System.debug('No customer details found in the response.');                                                                                                                 
                }
            } else {
                System.debug('Failed to get customer details. Status: ' + response.getStatusCode() + ', Response: ' + response.getBody());
            }
        } catch (Exception e) {
            System.debug('Exception occurred in getCustomerDetails: ' + e.getMessage());
        }
    } 
    private static void createOrUpdateAccount(String customerDisplayName, String qbCustomerEmail, String city, String postalCode, String companyName,String customerId) {
        if (String.isNotBlank(qbCustomerEmail)) {
            try {
                List<Account> existingAccounts = [SELECT Id, Name, Company_Email_Address__c, BillingCity, BillingPostalCode, Website 	
                                                  FROM Account 
                                                  WHERE quickBook_Customer_Id__c = :customerId
                                                  LIMIT 1];
                system.debug('existingAccounts : '+existingAccounts);
                if (!existingAccounts.isEmpty()) {
                    System.debug('Found existing account: ' + existingAccounts[0].Name);
                    Account accountToUpdate = existingAccounts[0];
                    accountToUpdate.Name = customerDisplayName;  
                    accountToUpdate.BillingCity = city != '' ? city : accountToUpdate.BillingCity;  
                    accountToUpdate.BillingPostalCode = postalCode != '' ? postalCode : accountToUpdate.BillingPostalCode; 
                    accountToUpdate.CompanyName__c = companyName; 
                    accountToUpdate.Company_Email_Address__c = qbCustomerEmail;
                    try {
                        update accountToUpdate;
                        System.debug('Account updated with new display name: ' + accountToUpdate.Name);
                    } catch (DmlException e) {
                        System.debug('DML Exception while updating account: ' + e.getMessage());
                    } catch (Exception e) {
                        System.debug('Exception while updating account: ' + e.getMessage());
                    }
                } else {
                    Account newAccount = new Account();
                    newAccount.Name = customerDisplayName;
                    newAccount.Company_Email_Address__c = qbCustomerEmail;
                    newAccount.BillingCity = city;
                    newAccount.BillingPostalCode = postalCode;
                    newAccount.CompanyName__c = companyName;
                    newAccount.quickBook_Customer_Id__c = customerId;
                    try {
                        insert newAccount;
                        System.debug('New Account created: ' + newAccount);
                    } catch (DmlException e) {
                        System.debug('DML Exception while inserting account: ' + e.getMessage());
                    } catch (Exception e) {
                        System.debug('Exception while inserting account: ' + e.getMessage());
                    }
                }
            } catch (Exception e) {
                System.debug('Exception in createOrUpdateAccount: ' + e.getMessage());
            }
        } else {
            System.debug('Invalid email address provided: ' + qbCustomerEmail);
        }
    } 
    //@future(callout=true)
    public static void getInvoiceDetails(String invoiceId) {
        Map<String,String> accessToken= new Map<String,String>();
        Datetime oneHourAgo = Datetime.now().addHours(-1);
        List<Generate_Refresh_Token__c> refreshToken = [ SELECT Id, Name, Refresh_Token__c, AccessToken__c , LastModifiedDate FROM Generate_Refresh_Token__c];
        if(refreshToken[0].LastModifiedDate < oneHourAgo){
            accessToken = getAccessToken();
        }
        else{
            system.debug('else part ');
            accessToken.put('access_token',refreshToken[0].AccessToken__c);
            accessToken.put('refresh_token',NULL);
        }
        
        
        //system.debug('isInvoiceAlreadyProcessed :: '+isInvoiceAlreadyProcessed);
        //if(isInvoiceAlreadyProcessed) return;
        //System.debug('getInvoiceDetails Called::' + invoiceId + accessToken);
        String companyId = Label.companyId;
        try {
            // isInvoiceAlreadyProcessed = true;
            Http http = new Http();
            HttpRequest request = new HttpRequest();
            request.setEndpoint('https://sandbox-quickbooks.api.intuit.com/v3/company/' + companyId + '/invoice/' + invoiceId);
            request.setMethod('GET');
            request.setHeader('Authorization', 'Bearer ' + accessToken.get('access_token'));
            request.setHeader('Accept', 'application/json');
            
            
            
            HttpResponse response = http.send(request);
            
            // Check for a successful status code
            if (response.getStatusCode() == 200) {
                system.debug('code success');
                // Deserialize the response to a map
                Map<String, Object> responseMap = (Map<String, Object>) JSON.deserializeUntyped(response.getBody());
                System.debug('Invoice details: ' + responseMap);
               /* QuickBooks_Integration__c quickss = new QuickBooks_Integration__c();
                quickss.id='a0lRu000004XHarIAG';
                quickss.Expires_In_Seconds__c =8;
                update quickss;*/
                
                List<Generate_Refresh_Token__c> refreshTokenObj = [SELECT Refresh_Token__c,	AccessToken__c FROM Generate_Refresh_Token__c];
                if (accessToken.get('refresh_token') != null) {
                    refreshTokenObj[0].Refresh_Token__c = accessToken.get('refresh_token');
                    refreshTokenObj[0].AccessToken__c = accessToken.get('access_token');
                    update refreshTokenObj;
                }
                
                
                
                if (responseMap.containsKey('Invoice')) {
                    Map<String, Object> invoice = (Map<String, Object>) responseMap.get('Invoice');
                    Decimal invoiceDeposit = (Decimal) invoice.get('Deposit');
                    Decimal totalAmount = (Decimal) invoice.get('TotalAmt');
                    Decimal dueBalance = (Decimal) invoice.get('Balance');
                    String invoiceNumber = (String) invoice.get('DocNumber');
                    String txnDate = (String) invoice.get('TxnDate');
                    String dueDate = (String) invoice.get('DueDate');
                    String customerName = (String) ((Map<String, Object>) invoice.get('CustomerRef')).get('name');
                    String customerEmail = (String) ((Map<String, Object>) invoice.get('BillEmail')).get('Address');
                    //getting invoice product details.
                    // Extract line items
                    List<Object> lineItems = (List<Object>) invoice.get('Line');
                    for (Object lineItemObj : lineItems) {
                        Map<String, Object> lineItem = (Map<String, Object>) lineItemObj;
                        if (lineItem.containsKey('SalesItemLineDetail')) {
                            Map<String, Object> salesDetail = (Map<String, Object>) lineItem.get('SalesItemLineDetail');
                            String lineId = (String) lineItem.get('Id');
                            String description = (String) lineItem.get('Description');
                            Decimal amount = (Decimal) lineItem.get('Amount');
                            Decimal unitPrice = (Decimal) salesDetail.get('UnitPrice');
                            Decimal quantity = (Decimal) salesDetail.get('Qty');
                            String itemName = (String) ((Map<String, Object>) salesDetail.get('ItemRef')).get('name');
                            System.debug('Line Item Details:');
                            System.debug('Line ID: ' + lineId);
                            if(lineId != null){
                                //createProductItems(itemName, description, quantity, unitPrice, amount, invoiceNumber);
                            }
                        }
                    }
                    //end invoice product
                    System.debug('invoiceDeposit:' + invoiceDeposit);
                    System.debug('dueAmount:' + dueBalance);
                    System.debug('TotalAmount:' + totalAmount);
                    System.debug('customerName: ' + customerName);
                    System.debug('customerEmail: ' + customerEmail);
                    System.debug('Invoice Number: ' + invoiceNumber);
                    System.debug('Transaction Date: ' + txnDate); 
                    System.debug('Due Date: ' + dueDate);
                    List<Account> accList  = [Select Id, Name, Company_Email_Address__c From Account Where Name =: customerName AND Company_Email_Address__c =: customerEmail];
                    if(accList.size() > 0){
                        String accId = accList[0].Id;
                        System.debug('Account Id::' + accId);
                        createOrUpdateInvoice(invoiceId, invoiceNumber, txnDate, dueDate, accId, totalAmount, dueBalance, invoiceDeposit); 
                    }
                    else{
                        String customerName1 = invoice.containsKey('CustomerRef') && ((Map<String, Object>) invoice.get('CustomerRef')).containsKey('name') 
                            ? (String) ((Map<String, Object>) invoice.get('CustomerRef')).get('name') : null;
                        
                        String customerEmail1 = invoice.containsKey('BillEmail') && ((Map<String, Object>) invoice.get('BillEmail')).containsKey('Address') 
                            ? (String) ((Map<String, Object>) invoice.get('BillEmail')).get('Address') : null;
                        
                        String customerStreet = invoice.containsKey('BillAddr') && ((Map<String, Object>) invoice.get('BillAddr')).containsKey('Line1') 
                            ? (String) (((Map<String, Object>) invoice.get('BillAddr')).get('Line1')) : '';
                        
                        String customerCity = invoice.containsKey('BillAddr') && ((Map<String, Object>) invoice.get('BillAddr')).containsKey('City') 
                            ? (String) ((Map<String, Object>) invoice.get('BillAddr')).get('City') : null;
                        
                        String customerCountry = invoice.containsKey('BillAddr') && ((Map<String, Object>) invoice.get('BillAddr')).containsKey('Country') 
                            ? (String) ((Map<String, Object>) invoice.get('BillAddr')).get('Country') : null;
                        
                        String customerState = invoice.containsKey('BillAddr') && ((Map<String, Object>) invoice.get('BillAddr')).containsKey('CountrySubDivisionCode') 
                            ? (String) ((Map<String, Object>) invoice.get('BillAddr')).get('CountrySubDivisionCode') : null;
                        
                        String customerPostalCode = invoice.containsKey('BillAddr') && ((Map<String, Object>) invoice.get('BillAddr')).containsKey('PostalCode') 
                            ? (String) ((Map<String, Object>) invoice.get('BillAddr')).get('PostalCode') : null;
                        
                        String customerId = invoice.containsKey('CustomerRef') && ((Map<String, Object>) invoice.get('CustomerRef')).containsKey('value') 
                            ? (String) ((Map<String, Object>) invoice.get('CustomerRef')).get('value') : null;
                        Account newAccount = new Account();
                        newAccount.Name = customerName1;
                        newAccount.Company_Email_Address__c = customerEmail1;
                        newAccount.BillingCity = customerCity;
                        newAccount.BillingPostalCode = customerPostalCode;
                        newAccount.CompanyName__c = customerName1;
                        newAccount.quickBook_Customer_Id__c = customerId;
                        
                        try {
                            insert newAccount;
                            System.debug('New Account created: ' + newAccount);
                            if(newAccount.Id != null){
                                createOrUpdateInvoice(invoiceId, invoiceNumber, txnDate, dueDate, newAccount.Id, totalAmount, dueBalance, invoiceDeposit); 
                            }
                        } catch (DmlException e) {
                            System.debug('DML Exception while inserting account: ' + e.getMessage());
                        } 
                    }
                }
            } else {
                System.debug('Failed to get invoice details. Status: ' + response.getStatusCode() + ', Response: ' + response.getBody());
            }
        } catch (Exception e) {
            System.debug('Exception occurred in getInvoiceDetails: ' + e.getMessage());
        }
    }
    // Method to create or update an invoice in Salesforce
    //@future(callout=true)
    private static void createOrUpdateInvoice(String invoiceId, String invoiceNumber, String txnDate, String dueDate, String accId, Decimal totalAmount, Decimal dueBalance, Decimal invoiceDeposit) {
        try {
            List<Invoice__c> existingInvoices = [SELECT Id, Total_Amount__c, Deposit__c, Due_Balance__c, Account__c, Invoice_Number__c, Date__c, Due_Date__c, Invoice_Id__c
                                                 FROM Invoice__c
                                                 WHERE Invoice_Id__c = :invoiceId
                                                 LIMIT 1];
            Invoice__c invoiceRecord;
            Boolean isNew = false;
            if (!existingInvoices.isEmpty()) {
                // Update existing Invoice__c record
                invoiceRecord = existingInvoices[0];
                invoiceRecord.Invoice_Number__c = invoiceNumber;
                invoiceRecord.Date__c = String.valueOf(txnDate);
                invoiceRecord.Due_Date__c = String.valueOf(dueDate);
                invoiceRecord.Account__c = accId;
                invoiceRecord.Total_Amount__c = totalAmount;
                invoiceRecord.Due_Balance__c = dueBalance;
                invoiceRecord.Deposit__c = invoiceDeposit;
                update invoiceRecord;
                System.debug('Invoice updated successfully: ' + invoiceRecord);
            } else {
                // Create new Invoice__c record
                invoiceRecord = new Invoice__c();
                invoiceRecord.Invoice_Id__c = invoiceId;
                invoiceRecord.Invoice_Number__c = invoiceNumber;
                invoiceRecord.Date__c = String.valueOf(txnDate);
                invoiceRecord.Due_Date__c = String.valueOf(dueDate);
                invoiceRecord.Account__c = accId;
                invoiceRecord.Total_Amount__c = totalAmount;
                invoiceRecord.Due_Balance__c = dueBalance;
                invoiceRecord.Deposit__c = invoiceDeposit;
                insert invoiceRecord;
                isNew = true;
                System.debug('New Invoice created: ' + invoiceRecord);
            }
            // Link Product_Items__c records to the Invoice__c record
            if (!createdProductItemIds.isEmpty()) {
                List<Product_Items__c> productItemsToUpdate = [SELECT Id, QuickBooks_Invoices__c FROM Product_Items__c WHERE Id IN :createdProductItemIds];
                System.debug('productItemsToUpdate' + productItemsToUpdate);
                for (Product_Items__c item : productItemsToUpdate) {
                    item.QuickBooks_Invoices__c = invoiceRecord.Id;
                }
                update productItemsToUpdate;
                System.debug('Product Items linked to Invoice: ' + productItemsToUpdate);
            }
            // Clear the createdProductItemIds list if it was a new invoice creation
            if (isNew) {
                createdProductItemIds.clear();
            }
            
        } catch (Exception e) {
            System.debug('Exception in createOrUpdateInvoice: ' + e.getMessage());
        }
    }
    
    public static List<String> createdProductItemIds = new List<String>();
    public static void createProductItems(String productName, String productDescription, Decimal productQty, Decimal productUnitPrice, Decimal productAmount, String invoiceNum) {
        try {
            
            List<Product_Items__c> existingProducts = [
                SELECT Id, Name, Description__c, Qty__c, Rate__c, Amount__c, Invoice_Number__c
                FROM Product_Items__c
                WHERE Name = :productName 
                AND Invoice_Number__c = :invoiceNum
                LIMIT 1
            ];
            
            Product_Items__c objProductItems;
            
            if (!existingProducts.isEmpty()) {
                // Update existing product item if found
                objProductItems = existingProducts[0];
                
                // Check if any field value differs before updating
                if (
                    objProductItems.Description__c != productDescription || 
                    objProductItems.Qty__c != productQty || 
                    objProductItems.Rate__c != productUnitPrice || 
                    objProductItems.Amount__c != productAmount
                ) {
                    objProductItems.Description__c = productDescription;
                    objProductItems.Qty__c = productQty;
                    objProductItems.Rate__c = productUnitPrice;
                    objProductItems.Amount__c = productAmount;
                    
                    update objProductItems;
                    System.debug('Updated Product Item: ' + objProductItems);
                    // Call new future method to delete matching products
                    
                } else {
                    System.debug('No update needed for existing Product Item: ' + objProductItems);
                }
            } else {
                // Create a new product item if no match is found
                objProductItems = new Product_Items__c();
                objProductItems.Name = productName;
                objProductItems.Description__c = productDescription;
                objProductItems.Qty__c = productQty;
                objProductItems.Rate__c = productUnitPrice;
                objProductItems.Amount__c = productAmount;
                objProductItems.Invoice_Number__c = invoiceNum;
                
                insert objProductItems;
                System.debug('Created New Product Item: ' + objProductItems);
                deleteProducts();
                deleteMatchingProducts(productName, productDescription, productQty, productUnitPrice, productAmount, invoiceNum);
            }
            
            // Ensure the product item's ID is added to the list only once
            if (!createdProductItemIds.contains(objProductItems.Id)) {
                createdProductItemIds.add(objProductItems.Id);
            }
            System.debug('createdProductItemIds: ' + createdProductItemIds);
            
        } catch (Exception e) {
            System.debug('ProductException: ' + e.getMessage());
        }
    }
    @future(callout=true)
    public static void deleteProducts() {
        try {
            List<Product_Items__c> lstOfProductsItems = [
                SELECT Id 
                FROM Product_Items__c 
                WHERE QuickBooks_Invoices__c = null
                LIMIT 20
            ];
            
            if (!lstOfProductsItems.isEmpty()) {
                delete lstOfProductsItems;
                System.debug('Deleted Product Items: ' + lstOfProductsItems.size());
            } else {
                System.debug('No Product Items to delete.');
            }
        } catch (DmlException dmle) {
            System.debug('DML Exception while deleting products: ' + dmle.getMessage());
        } catch (Exception e) {
            System.debug('Exception while deleting products: ' + e.getMessage());
        }
    }
    
    @future(callout=true)
    public static void deleteMatchingProducts(String productName, String productDescription, Decimal productQty, Decimal productUnitPrice, Decimal productAmount, String invoiceNum) {
        /*try {
// Query for products that match the provided criteria
List<Product_Items__c> matchingProducts = [
SELECT Id, Name, Description__c, Qty__c, Rate__c, Amount__c, Invoice_Number__c, CreatedDate
FROM Product_Items__c
WHERE Name = :productName
AND Description__c = :productDescription
AND Qty__c = :productQty
AND Rate__c = :productUnitPrice
AND Amount__c = :productAmount
AND Invoice_Number__c = :invoiceNum
ORDER BY CreatedDate ASC
];

// Map to store the last record for each duplicate group
Map<String, Product_Items__c> lastProductMap = new Map<String, Product_Items__c>();

for (Product_Items__c product : matchingProducts) {
String uniqueKey = product.Name + '|' + product.Description__c + '|' + 
product.Qty__c + '|' + product.Rate__c + '|' + 
product.Amount__c + '|' + product.Invoice_Number__c;

// Keep overwriting with the latest record in the sorted list
lastProductMap.put(uniqueKey, product);
}

// Extract IDs to delete
Set<Id> idsToKeep = new Set<Id>();
for (Product_Items__c product : lastProductMap.values()) {
idsToKeep.add(product.Id);
}

// Prepare list of records to delete
List<Product_Items__c> productsToDelete = new List<Product_Items__c>();
for (Product_Items__c product : matchingProducts) {
if (!idsToKeep.contains(product.Id)) {
productsToDelete.add(product);
}
}

// Perform the deletion if there are records to delete
if (!productsToDelete.isEmpty()) {
delete productsToDelete;
System.debug('Deleted Duplicate Product Items: ' + productsToDelete.size());
} else {
System.debug('No Duplicate Product Items found for deletion.');
}
} catch (DmlException dmle) {
System.debug('DML Exception while deleting matching products: ' + dmle.getMessage());
} catch (Exception e) {
System.debug('Exception while deleting matching products: ' + e.getMessage());
}
} */
    }
    /*public static void processTxnId(String txnId,String refresh_token, String access_token) {
        List<RefreshTokenQuickBook__c> refreshToken = [SELECT RefreshToken__c,	AccessToken__c FROM RefreshTokenQuickBook__c];
         if (refresh_token != null) {
             refreshToken[0].RefreshToken__c = refresh_token;
             refreshToken[0].AccessToken__c = access_token;
             update refreshToken;
         }
        
    }*/
    
}