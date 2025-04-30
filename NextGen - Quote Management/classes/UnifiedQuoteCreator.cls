public class UnifiedQuoteCreator {
    @InvocableMethod(label='' description='Creates a quote and returns output as summary text.')
    public static List<QuoteOutputWrapper> createQuote(List<QuoteInputWrapper> requests) {
        List<QuoteOutputWrapper> responses = new List<QuoteOutputWrapper>();

        for (QuoteInputWrapper request : requests) {
            QuoteOutputWrapper response = new QuoteOutputWrapper();
            String summary = '';

            try {
                // Fetch Opportunity
                Opportunity opp = [SELECT Id, Name, AccountId, Pricebook2Id, Account.Name
                                   FROM Opportunity 
                                   WHERE Name = :request.opportunityName 
                                   LIMIT 1];

                if (opp.Pricebook2Id == null) {
                    response.outputSummary = 'Opportunity "' + opp.Name + '" has no Pricebook associated.';
                    responses.add(response);
                    continue;
                }

                // Create Quote
                Quote newQuote = new Quote(
                    Name = opp.Name + ' - Quote',
                    OpportunityId = opp.Id,
                    Pricebook2Id = opp.Pricebook2Id,
                    ExpirationDate = System.today().addMonths(1),
                    Status = 'Draft'
                );
                insert newQuote;

                newQuote = [SELECT Id, QuoteNumber, ExpirationDate FROM Quote WHERE Id = :newQuote.Id];

                // Fetch Pricebook Entries
                List<PricebookEntry> pricebookEntries = [SELECT Id, Product2Id, UnitPrice, Product2.Name, Product2.ProductCode 
                                                         FROM PricebookEntry 
                                                         WHERE Product2.ProductCode IN :request.productCodes 
                                                         AND Pricebook2Id = :opp.Pricebook2Id 
                                                         AND IsActive = TRUE];

                if (pricebookEntries.isEmpty()) {
                    response.outputSummary = 'No matching products found in Pricebook for Opportunity "' + opp.Name + '".';
                    responses.add(response);
                    continue;
                }

                // Map Product Codes to Pricebook Entries
                Map<String, PricebookEntry> productMap = new Map<String, PricebookEntry>();
                for (PricebookEntry entry : pricebookEntries) {
                    Product2 product = [SELECT ProductCode, Name FROM Product2 WHERE Id = :entry.Product2Id];
                    productMap.put(product.ProductCode, entry);
                }

                // Create Quote Line Items
                List<QuoteLineItem> qlis = new List<QuoteLineItem>();

                summary += 'Quote Number: ' + newQuote.QuoteNumber + '\n';
                summary += 'Expiration Date: ' + String.valueOf(newQuote.ExpirationDate) + '\n';
                summary += 'Account Name: ' + opp.Account.Name + '\n';
                summary += 'Line Items:\n';

                for (Integer i = 0; i < request.productCodes.size(); i++) {
                    String code = request.productCodes[i];
                    Integer qty = request.quantities[i];

                    if (productMap.containsKey(code)) {
                        PricebookEntry entry = productMap.get(code);
                        QuoteLineItem qli = new QuoteLineItem(
                            QuoteId = newQuote.Id,
                            PricebookEntryId = entry.Id,
                            Quantity = qty,
                            UnitPrice = entry.UnitPrice
                        );
                        qlis.add(qli);

                        Decimal total = entry.UnitPrice * qty;
                        summary += '- Product: ' + entry.Product2.Name +
                                   ', Quantity: ' + qty +
                                   ', Unit Price: ' + entry.UnitPrice +
                                   ', Total Price: ' + total + '\n';
                    }
                }

                if (!qlis.isEmpty()) {
                    insert qlis;
                }

                response.outputSummary = summary;
                responses.add(response);

            } catch (Exception e) {
                response.outputSummary = 'Error occurred for Opportunity "' + request.opportunityName + '": ' + e.getMessage();
                responses.add(response);
            }
        }

        return responses;
    }

    public class QuoteInputWrapper {
        @InvocableVariable(label='Opportunity Name' required=true)
        public String opportunityName;

        @InvocableVariable(label='Product Codes' required=true)
        public List<String> productCodes;

        @InvocableVariable(label='Quantities' required=true)
        public List<Integer> quantities;
    }

    public class QuoteOutputWrapper {
        @InvocableVariable(label='Output Summary')
        public String outputSummary;
    }
}