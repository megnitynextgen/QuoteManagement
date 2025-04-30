public class QuoteComparisonHandler {
    @InvocableMethod(label='Compare Quotes and Return Summary')
    public static List<QuoteComparisonOutput> compareQuotes(List<QuoteComparisonInput> inputs) {
        List<QuoteComparisonOutput> results = new List<QuoteComparisonOutput>();
        for (QuoteComparisonInput input : inputs) {
            QuoteComparisonOutput output = new QuoteComparisonOutput();
            String summary = '';
            try {
                // Fetch Opportunity with Account Name
                Opportunity opp = [
                    SELECT Id, Name, Account.Name
                    FROM Opportunity
                    WHERE Name = :input.opportunityName
                    LIMIT 1
                ];
                // Fetch current (new) quote by QuoteNumber
                Quote currentQuote = [
                    SELECT Id, QuoteNumber, Subtotal, Discount, TotalPrice, GrandTotal, ExpirationDate
                    FROM Quote
                    WHERE QuoteNumber = :input.newQuoteNumber
                    AND OpportunityId = :opp.Id
                    LIMIT 1
                ];
                // Fetch last accepted quote
                List<Quote> acceptedQuotes = [
                    SELECT Id, QuoteNumber, Subtotal, Discount, TotalPrice, GrandTotal, ExpirationDate
                    FROM Quote
                    WHERE OpportunityId = :opp.Id AND Status = 'Accepted'
                    ORDER BY CreatedDate DESC
                    LIMIT 1
                ];
                if (acceptedQuotes.isEmpty()) {
                    output.comparisonSummary = '❗ No accepted quote found for Opportunity "' + input.opportunityName + '".';
                    results.add(output);
                    continue;
                }
                Quote acceptedQuote = acceptedQuotes[0];
                // Build plain text summary
                summary += '📌 Opportunity: ' + opp.Name + '\n';
                summary += '📌 Account: ' + opp.Account.Name + '\n\n';
                summary += '🆕 New Quote (' + currentQuote.QuoteNumber + '):\n';
                summary += '- Subtotal: $' + currentQuote.Subtotal.setScale(2) + '\n';
                summary += '- Discount: $' + currentQuote.Discount.setScale(2) + '\n';
                summary += '- Total Price: $' + currentQuote.TotalPrice.setScale(2) + '\n';
                summary += '- Grand Total: $' + currentQuote.GrandTotal.setScale(2) + '\n';
                summary += '- Expiration Date: ' + String.valueOf(currentQuote.ExpirationDate) + '\n\n';
                summary += '✅ Last Accepted Quote (' + acceptedQuote.QuoteNumber + '):\n';
                summary += '- Subtotal: $' + acceptedQuote.Subtotal.setScale(2) + '\n';
                summary += '- Discount: $' + acceptedQuote.Discount.setScale(2) + '\n';
                summary += '- Total Price: $' + acceptedQuote.TotalPrice.setScale(2) + '\n';
                summary += '- Grand Total: $' + acceptedQuote.GrandTotal.setScale(2) + '\n';
                summary += '- Expiration Date: ' + String.valueOf(acceptedQuote.ExpirationDate) + '\n';
                output.comparisonSummary = summary;
            } catch (Exception e) {
                output.comparisonSummary = '⚠️ Error: ' + e.getMessage();
            }
            results.add(output);
        }
        return results;
    }
    public class QuoteComparisonInput {
        @InvocableVariable(label='Opportunity Name' required=true)
        public String opportunityName;
        @InvocableVariable(label='New Quote Number' required=true)
        public String newQuoteNumber;
    }
    public class QuoteComparisonOutput {
        @InvocableVariable(label='Comparison Summary')
        public String comparisonSummary;
    }
}