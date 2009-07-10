require 'rubygems'
require 'builder'
require 'digest/sha1'

module OFX
  module Statement
    class Base
      attr_reader   :builder_class
      attr_writer   :currency, :server_response_time, :language
      attr_accessor :account_number, :start_date, :end_date, 
                    :date, :ledger_balance
      
      def initialize(format = :ofx2)
        case format
        when :ofx1
          @builder_class = OFX::Statement::Output::Builder::OFX1
        when :ofx2
          @builder_class = OFX::Statement::Output::Builder::OFX2
        end
      end
      
      def currency
        @currency ||= 'GBP'
      end
      
      def language
        @language ||= 'ENG'
      end
      
      def server_response_time
        @server_response_time ||= Time.now
      end
      
      def <<(transaction)
        transaction.statement = self
        transactions << transaction
      end
      
      def transactions
        @transactions ||= []
      end
      
      def fitid_for(transaction)
        index = transactions.index(transaction)
        Digest::SHA1.hexdigest(self.date.strftime('%Y%m%d') + transaction.date.strftime('%Y%m%d') + index.to_s)
      end
      
      def serialise(format = :ofx2)
        output.new.serialise(self, format)
      end
    end
  end
end