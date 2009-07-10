require 'ofx/statement/output/base'

module OFX
  module Statement
    module Output
      class CreditCard < OFX::Statement::Output::Base
        def message_set_block(node)
          return node.CREDITCARDMSGSETV1 unless block_given?
          node.CREDITCARDMSGSETV1 { |child| yield(child) }
        end
        
        def statement_block(node, statement)
          node.CCSTMTTRNRS do |ccstmttrnrs|
            ccstmttrnrs.CCSTMTRS do |ccstmtrs|
              ccstmtrs.CURDEF statement.currency
              ccstmtrs.CCACCTFROM do |ccacctfrom|
                ccacctfrom.ACCTID statement.account_number
              end
              transaction_list(ccstmtrs, statement) { |list_node| yield(list_node) if block_given? }
              ledger_balance_block(ccstmtrs, statement)
              ccstmtrs.AVAILBAL do |availbal|
                availbal.BALAMT statement.available_credit
                availbal.DTASOF time_to_ofx_dta(statement.date)
              end
            end
          end
        end
      end
    end
  end
end
