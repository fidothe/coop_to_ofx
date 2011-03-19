require 'ofx/statement/base'
require 'ofx/statement/output/savings_account'

module OFX
  module Statement
    class SavingsAccount < OFX::Statement::Base
      attr_accessor :sort_code
      
      def output
        OFX::Statement::Output::SavingsAccount
      end
    end
  end
end
