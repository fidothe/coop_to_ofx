require 'ofx/statement/base'
require 'ofx/statement/output/current_account'

module OFX
  module Statement
    class CurrentAccount < OFX::Statement::Base
      attr_accessor :sort_code
      
      def output
        OFX::Statement::Output::CurrentAccount
      end
    end
  end
end
