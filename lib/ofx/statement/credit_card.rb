require 'rubygems'
require 'builder'

module OFX
  module Statement
    class CreditCard < OFX::Base
      class << self
        def ofx_pi(node)
          node.instruct! :OFX, :OFXHEADER => "200", :VERSION => "203", :SECURITY => "NONE", 
                               :OLDFILEUID => "NONE", :NEWFILEUID => "NONE"
        end
        
        def ofx_block(node)
          return node.OFX unless block_given?
          node.OFX { |child| yield(child) }
        end
        
        def signon_block(node, server_response_time, language)
          node.SIGNONMSGSRSV1 do |signonmsgrsv1|
            signonmsgrsv1.SONRS do |sonrs|
              sonrs.STATUS do |status|
                status.CODE "0"
                status.SEVERITY "INFO"
              end
              sonrs.DTSERVER time_to_ofx_dta(server_response_time, true)
              sonrs.LANGUAGE language
            end
            yield(signonmsgrsv1) if block_given?
          end
        end
        
        def message_set_block(node)
          return node.CREDITCARDMSGSETV1 unless block_given?
          node.CREDITCARDMSGSETV1 { |child| yield(child) }
        end
        
        def statement_block(node, account_number, date, start_date, end_date, currency, statement_ledger_balance, available_credit)
          node.CCSTMTTRNRS do |ccstmttrnrs|
            ccstmttrnrs.CCSTMTRS do |ccstmtrs|
              ccstmtrs.CURDEF currency
              ccstmtrs.CCACCTFROM do |ccacctfrom|
                ccacctfrom.ACCTID account_number
              end
              ccstmtrs.BANKTRANLIST do |banktranlist|
                banktranlist.DTSTART time_to_ofx_dta(start_date)
                banktranlist.DTEND time_to_ofx_dta(end_date)
                yield(ccstmtrs) if block_given?
              end
              ccstmtrs.LEDGERBAL do |ledgerbal|
                ledgerbal.BALAMT statement_ledger_balance
                ledgerbal.DTASOF time_to_ofx_dta(date)
              end
              ccstmtrs.AVAILBAL do |availbal|
                availbal.BALAMT available_credit
                availbal.DTASOF time_to_ofx_dta(date)
              end
            end
          end
        end
        
        def transaction_block(node, transaction)
          node.STMTTRN do |stmttrn|
            stmttrn.TRNTYPE generate_trntype(transaction.amount)
            stmttrn.DTPOSTED time_to_ofx_dta(transaction.date)
            stmttrn.TRNAMT transaction.amount
            stmttrn.FITID generate_fitid(transaction.date)
            stmttrn.NAME transaction.name
            stmttrn.MEMO transaction.memo if transaction.has_memo?
          end
        end
        
        def generate(node, statement)
          ofx_pi(node)
          ofx_block(node) do |ofx|
            signon_block(ofx, statement.server_response_time, statement.language) do |signon|
              message_set_block(signon) do |message_set|
                statement_block(message_set, statement.account_number, statement.date, 
                                statement.start_date, statement.end_date, 
                                statement.currency, statement.ledger_balance, statement.available_credit) do |stmnt|
                                  statement.transactions.each do |transaction|
                                    transaction_block(stmnt, transaction)
                                  end
                                end
              end
            end
          end
          
        end
      end
      
      attr_writer   :currency, :server_response_time, :language, :transactions
      attr_accessor :account_number, :start_date, :end_date, 
                    :date, :ledger_balance, :available_credit
      
      def currency
        @currency ||= 'GBP'
      end
      
      def language
        @language ||= 'ENG'
      end
      
      def server_response_time
        @server_response_time ||= Time.now
      end
      
      def transactions
        @transactions ||= []
      end
      
      def builder
        @builder ||= Builder::XmlMarkup.new(:indent => 2)
      end
      
      def serialise
        builder.instruct!
        
        self.class.generate(builder, self)
        
        builder.target!
      end
    end
  end
end