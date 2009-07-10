require 'rubygems'
require 'hpricot'

require 'coop_scraper/base'
require 'ofx/statement'

module CoopScraper
  class CreditCard
    class << self
      include CoopScraper::Base
      
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
      
      def determine_trntype(details)
        case details
        when /^OVERLIMIT CHARGE$/
          :service_charge
        when /^MERCHANDISE INTEREST AT [0-9]+\.[0-9]+% PER MTH$/
          :interest
        else
          nil
        end
      end
      
      def extract_transactions(doc, statement)
        transactions = []
        current_transaction = {}
        doc.search('tbody.contents tr').each do |statement_row|
          date = statement_row.at('td.dataRowL').inner_text
          unless date == "?" || date[0] == 194
            current_transaction = extract_transaction(statement_row, coop_date_to_time(date))
            transactions << current_transaction
          else
            transaction = extract_transaction(statement_row, statement.date)
            if transaction[:details].match(/OVERLIMIT CHARGE/)
              transactions << transaction
            else
              conversion_details = transaction[:details]
              current_transaction[:conversion] = conversion_details unless conversion_details.match(/ESTIMATED INTEREST/)
            end
          end
        end
        transactions.collect do |t| 
          options = {}
          options[:memo] = t[:conversion] if t[:conversion]
          trntype = determine_trntype(t[:details])
          options[:trntype] = trntype unless trntype.nil?
          OFX::Statement::Transaction.new(t[:amount], t[:date], t[:details], options)
        end
      end
      
      def extract_transaction(statement_row, date)
        details = statement_row.at('td.transData').inner_text.strip
        credit = statement_row.at('td.moneyData:first').inner_text.match(/[0-9.]+/)
        debit = statement_row.at('td.moneyData:last').inner_text.match(/[0-9.]+/)
        amount = credit.nil? ? "-#{debit}" : credit.to_s
        {:date => date, :amount => amount, :details => details}
      end
      
      def generate_statement(html_statement_io, server_response_time)
        doc = Hpricot(html_statement_io)
        statement = OFX::Statement::CreditCard.new
        
        statement.server_response_time = server_response_time
        statement.account_number = extract_account_number(doc)
        statement.date = extract_statement_date(doc)
        statement.ledger_balance = extract_statement_balance(doc)
        statement.available_credit = extract_available_credit(doc)

        extract_transactions(doc, statement).each { |transaction| statement << transaction }

        statement.start_date = statement.transactions.first.date
        statement.end_date = statement.date
        statement
      end
    end
  end
end