require 'ofx/statement/credit_card'

module CoopScraper
  class CreditCard
    class << self
      def extract_statement_date(doc)
        coop_date_to_time(doc.at("td[text()='Statement Date'] ~ td").inner_text)
      end

      def extract_account_number(doc)
        doc.at("h4[text()*='TRAVEL CARD']").inner_text.match(/([0-9]{16})/)[1]
      end

      def extract_statement_balance(doc)
        amount, sign = doc.at("td[text()='Statement Balance'] ~ td").inner_text.match(/([0-9.]+) *(DR)?/).captures
        amount = "-#{amount}" if sign == "DR"
        amount
      end

      def extract_available_credit(doc)
        doc.at("td[text()='Available Credit'] ~ td").inner_text.match(/[0-9.]+/).to_s
      end

      def extract_transactions(doc)
        transactions = []
        current_transaction = {}
        doc.search('tbody.contents tr').each do |statement_row|
          date = statement_row.at('td.dataRowL').inner_text
          unless date == "?"
            details = statement_row.at('td.transData').inner_text.strip
            credit = statement_row.at('td.moneyData:first').inner_text.match(/[0-9.]+/)
            debit = statement_row.at('td.moneyData:last').inner_text.match(/[0-9.]+/)
            amount = credit.nil? ? "-#{debit}" : credit.to_s
            current_transaction = {:date => coop_date_to_time(date), :amount => amount, :details => details}
            transactions << current_transaction
          else
            conversion_details = statement_row.at('td.transData').inner_text.strip
            current_transaction[:conversion] = conversion_details unless conversion_details.match(/ESTIMATED INTEREST/)
          end
        end
        transactions.collect { |t| OFX::Statement::Transaction.new(t[:amount], t[:date], t[:details], t[:conversion])}
      end

      def coop_date_to_time(coop_date)
        day, month, year = coop_date.match(/([0-9]{2})\/([0-9]{2})\/([0-9]{4})/).captures
        Time.utc(year, month, day)
      end
      
      def generate_statement(html_statement_io, server_response_time)
        doc = Hpricot(html_statement_io)
        statement = OFX::Statement::CreditCard.new
        
        statement.server_response_time = server_response_time
        statement.account_number = extract_account_number(doc)
        statement.date = extract_statement_date(doc)
        statement.ledger_balance = extract_statement_balance(doc)
        statement.available_credit = extract_available_credit(doc)

        statement.transactions = extract_transactions(doc)

        statement.start_date = statement.transactions.first.date
        statement.end_date = statement.transactions.last.date
        statement
      end
    end
  end
end