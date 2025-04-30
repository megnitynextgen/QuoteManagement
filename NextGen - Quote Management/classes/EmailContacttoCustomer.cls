public class EmailContacttoCustomer {

    // ✅ Output wrapper class
    public class QuoteOutputWrapper {
        @InvocableVariable(label='Output Summary')
        public String outputSummary;
    }

    @InvocableMethod(label='Email Quote to Customer' description='Sends the quote PDF to the customer via email when requested by the agent')
    public static List<QuoteOutputWrapper> sendQuoteEmail(List<String> quoteNumbers) {

        for (String quoteNumber : quoteNumbers) {
            try {
                System.debug('Processing Quote Number: ' + quoteNumber);

                Quote q = [
                    SELECT Id, Name, QuoteNumber, TotalPrice, ExpirationDate, Contact.Email, Contact.FirstName, Contact.LastName
                    FROM Quote
                    WHERE QuoteNumber = :quoteNumber
                    LIMIT 1
                ];
                System.debug('Fetched Quote: Id=' + q.Id + ', Name=' + q.Name + ', Contact Email=' + (q.Contact != null ? q.Contact.Email : 'null'));

                Contact customer = q.Contact;

                if (customer != null && String.isNotBlank(customer.Email)) {

                    System.debug('Generating PDF from Visualforce page for Quote Id: ' + q.Id);

                    PageReference pdfPage = Page.GenerateQuotePDFViewer;
                    pdfPage.getParameters().put('id', q.Id);
                    Blob pdfBlob = pdfPage.getContentAsPDF();

                    Messaging.SingleEmailMessage mail = new Messaging.SingleEmailMessage();
                    mail.setToAddresses(new List<String>{ customer.Email });
                    mail.setSubject('Quote Proposal - ' + q.Name);

                    String emailBody = 'Dear ' + customer.FirstName + ',<br/><br/>' +
                        'I hope this message finds you well. Attached to this email, you will find the quote proposal detailing the services requested. ' +
                        'The total price for the services amounts to $' + String.valueOf(q.TotalPrice) + '. Please review the proposal at your convenience.<br/><br/>' +
                        'Kindly note that the quote is valid until ' + q.ExpirationDate.format() + '. Should you have any questions or require further clarification, feel free to reach out to me.<br/><br/>' +
                        'Best Regards,<br/>Your Company Name';

                    mail.setHtmlBody(emailBody);

                    Messaging.EmailFileAttachment attachment = new Messaging.EmailFileAttachment();
                    attachment.setFileName(q.Name + '.pdf');
                    attachment.setBody(pdfBlob);
                    attachment.setContentType('application/pdf');

                    mail.setFileAttachments(new Messaging.EmailFileAttachment[] { attachment });

                    System.debug('Email prepared to: ' + customer.Email);
                    System.debug('Sending email with attachment: ' + q.Name + '.pdf');

                    Messaging.sendEmail(new Messaging.SingleEmailMessage[] { mail });

                    System.debug('Email sent successfully.');
                } else {
                    System.debug('No valid contact email found for Quote Number: ' + quoteNumber);
                }

            } catch (Exception e) {
                System.debug('Error while sending email: ' + e.getMessage());
            }
        }

        // ✅ Return static success message as output
        QuoteOutputWrapper output = new QuoteOutputWrapper();
        output.outputSummary = 'Email sending process completed.';
        return new List<QuoteOutputWrapper>{ output };
    }
}