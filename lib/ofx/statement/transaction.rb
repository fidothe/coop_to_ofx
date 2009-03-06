module OFX
  module Statement
    class Transaction
      attr_reader :amount, :date, :name, :memo
      
      def initialize(amount, date, name, memo = nil)
        @amount = amount
        @date = date
        @name = name
        @memo = memo
      end
      
      def has_memo?
        !(memo.nil? || memo.empty?)
      end
    end
  end
end
