require 'ofx/statement/output/base'

module OFX
  module Statement
    module Output
      class SavingsAccount < OFX::Statement::Output::Base
        def message_set_block(node)
          return node.BANKMSGSETV1 unless block_given?
          node.BANKMSGSETV1 { |child| yield(child) }
        end
        
        def statement_block(node, statement)
          node.STMTTRNRS do |stmttrnrs|
            stmttrnrs.STMTRS do |stmtrs|
              stmtrs.CURDEF statement.currency
              stmtrs.BANKACCTFROM do |bankacctfrom|
                bankacctfrom.BANKID statement.sort_code
                bankacctfrom.ACCTID statement.account_number
                bankacctfrom.ACCTTYPE "SAVINGS"
              end
              transaction_list(stmtrs, statement) { |list_node| yield(list_node) if block_given? }
              ledger_balance_block(stmtrs, statement)
            end
          end
        end
      end
    end
  end
end
