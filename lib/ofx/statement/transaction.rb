module OFX
  module Statement
    class Transaction
      class << self
        def valid_trntypes
          @valid_trntypes ||= OFX::Statement::Output::Base.trntype_hash.keys
        end
      end
      
      attr_reader :amount, :date, :name, :memo, :trntype
      attr_accessor :statement
      
      def initialize(amount, date, name, options = {})
        @amount = amount
        @date = date
        @name = name
        @memo = options[:memo]
        @trntype = verify_trntype(options[:trntype].nil? ? default_trntype : options[:trntype])
      end
      
      def has_memo?
        !(memo.nil? || memo.empty?)
      end
      
      def fitid
        statement.fitid_for(self)
      end
      
      private
      
      def default_trntype
        amount.match(/^-/) ? :debit : :credit
      end
      
      def verify_trntype(trntype)
        raise UnknownTrntype, trntype unless self.class.valid_trntypes.include?(trntype)
        trntype
      end
    end
    
    class UnknownTrntype < StandardError
      def initialize(trntype)
        super()
        @trntype = trntype
      end
      
      def to_s
        "Unknown Trntype #{@trntype.inspect}"
      end
    end
  end
end
