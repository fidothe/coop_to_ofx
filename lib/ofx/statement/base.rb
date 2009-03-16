require 'rubygems'
require 'builder'
require 'digest/sha1'

module OFX
  module Statement
    class Base
      attr_writer   :currency, :server_response_time, :language
      attr_accessor :account_number, :start_date, :end_date, 
                    :date, :ledger_balance
      
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
      
      def builder
        @builder ||= Builder::XmlMarkup.new(:indent => 2)
      end
      
      def serialise
        output.serialise(builder, self)
        
        builder.target!
      end
    end
  end
end