require 'ofx/statement/base'
require 'ofx/statement/output/credit_card'


module OFX
  module Statement
    class CreditCard < OFX::Statement::Base
      attr_accessor :available_credit
      
      def output
        OFX::Statement::Output::CreditCard
      end
    end
  end
end