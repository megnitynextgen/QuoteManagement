public class QuotePDFHandler {

    @InvocableMethod(label='Generate Quote File' description='Generates a Quote PDF for the specified Quote Number')

    public static List<String> generateQuoteFile(List<String> quoteNumbers) {

        List<String> pdfLinks = new List<String>();
 
        for (String quoteNumber : quoteNumbers) {

            try {

                // Fetch the quote record

                Quote q = [SELECT Id,Name,Account.Name,Opportunity.Name FROM Quote WHERE QuoteNumber = :quoteNumber LIMIT 1];

                if (q != null) {

                    // Generate the clickable PDF URL

                    String pdfLink = '<a href="' + System.Url.getOrgDomainUrl().toExternalForm() 

                        + '/apex/GenerateQuotePDFViewer?id=' + q.Id 

                        + '" target="_blank">'+q.Name+'</a>';

                    pdfLinks.add(pdfLink);

                }

            } catch (Exception e) {

                System.debug('Error while generating PDF: ' + e.getMessage());

                pdfLinks.add('Error: ' + e.getMessage());

            }


        }



        return pdfLinks;

    }

}