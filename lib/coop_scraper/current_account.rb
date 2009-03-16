require 'rubygems'
require 'hpricot'

require 'coop_scraper/base'
require 'ofx/statement'

module CoopScraper
  module CurrentAccount
    class << self
      include CoopScraper::Base
      
      def extract_account_number(doc)
        doc.at("h4[text()*='CURRENT ACCOUNT']").inner_text.match(/([0-9]{8})/)[1]
      end
      
      def extract_sort_code(doc)
        doc.at("h4[text()*='CURRENT ACCOUNT']").inner_text.match(/([0-9]{2}-[0-9]{2}-[0-9]{2})/)[1].tr('-', '')
      end
      
      def extract_statement_date(doc)
        coop_date_to_time(doc.at("td[text()^='Date']").inner_text)
      end
      
      def extract_transaction_rows(doc)
        a_td = doc.at('td.transData')
        a_td.parent.parent.search('tr')
      end
      
      def determine_trntype(details)
        case details
        when /^DEBIT INTEREST$/
          :interest
        when /^LINK +[0-9]{2}:[0-9]{2}[A-Z]{3}[0-9]{2}$/
          :atm
        when /^SERVICE CHARGE$/
          :service_charge
        when /^TFR [0-9]{14}$/
          :transfer
        else
          nil
        end
      end
      
      def extract_transactions(doc)
        transactions = []
        a_td = doc.at('td.transData')
        transaction_rows = extract_transaction_rows(doc)
        first_row = transaction_rows.shift
        transaction_rows.each do |statement_row|
          date = statement_row.at('td.dataRowL').inner_text
          details = statement_row.at('td.transData').inner_text.strip
          credit = statement_row.at('td.moneyData:first').inner_text.match(/[0-9.]+/)
          debit = statement_row.search('td.moneyData')[1].inner_text.match(/[0-9.]+/)
          amount = credit.nil? ? "-#{debit}" : credit.to_s
          options = {}
          trntype = determine_trntype(details)
          options[:trntype] = trntype unless trntype.nil?
          transactions << OFX::Statement::Transaction.new(amount, coop_date_to_time(date), details, options)
        end
        transactions
      end
      
      def extract_closing_balance(doc)
        final_transaction = extract_transaction_rows(doc).last.at('td.moneyData:last').inner_text
        amount = final_transaction.match(/[0-9.]+/).to_s
        sign = final_transaction.match(/[CD]R/).to_s
        sign == "CR" ? amount : "-#{amount}"
      end
      
      def extract_statement_start_date(doc)
        coop_date_to_time(extract_transaction_rows(doc).first.at('td.dataRowL').inner_text)
      end
      
      def generate_statement(html_statement_io, server_response_time)
        doc = Hpricot(html_statement_io)
        statement = OFX::Statement::CurrentAccount.new
        
        statement.server_response_time = server_response_time
        statement.account_number = extract_account_number(doc)
        statement.sort_code = extract_sort_code(doc)
        statement.date = extract_statement_date(doc)
        statement.ledger_balance = extract_closing_balance(doc)
        
        extract_transactions(doc).each { |transaction| statement << transaction }
        
        statement.start_date = extract_statement_start_date(doc)
        statement.end_date = extract_statement_date(doc)
        statement
      end
    end
  end
end
