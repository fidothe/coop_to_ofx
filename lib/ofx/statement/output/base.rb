module OFX
  module Statement
    module Output
      module Base
        class << self
          # See OFX 2.0.3 spec, section 11.4.3.1 "Transaction types used in <TRNTYPE>"
          def trntype_hash
            @trntype_hash ||= {
              :debit => "DEBIT",
              :credit => "CREDIT",
              :interest => "INT",
              :dividend => "DIV",
              :fee => "FEE", 
              :service_charge => "SRVCHG", 
              :deposit => "DEP", 
              :atm => "ATM", 
              :point_of_sale => "POS", 
              :transfer => "XFER", 
              :cheque => "CHECK", 
              :check => "CHECK",
              :payment => "PAYMENT", 
              :cash => "CASH", 
              :direct_deposit => "DIRECTDEP",
              :direct_debit => "DIRECTDEBIT", 
              :repeating_payment => "REPEATPMT",
              :standing_order => "REPEATPMT", 
              :other => "OTHER"
            }
          end
        end
        
        def fitid_hash
          @fitid_hash ||= {}
        end
        
        def time_to_ofx_dta(timeobj, extended=false)
          fmt = '%Y%m%d' + (extended ? '%H%M%S' : '')
          timeobj.strftime(fmt)
        end
        
        def generate_fitid(time)
          date = time_to_ofx_dta(time)
          suffix = fitid_hash[date].nil? ? 1 : fitid_hash[date] + 1
          fitid_hash[date] = suffix
          "#{date}#{suffix}"
        end
        
        def generate_trntype(trntype)
          output = OFX::Statement::Output::Base.trntype_hash[trntype]
          raise UnknownTrntype, trntype unless output
          output
        end
        
        def ofx_pi(node)
          node.instruct! :OFX, :OFXHEADER => "200", :VERSION => "203", :SECURITY => "NONE", 
                               :OLDFILEUID => "NONE", :NEWFILEUID => "NONE"
        end
        
        def ofx_block(node)
          return node.OFX unless block_given?
          node.OFX { |child| yield(child) }
        end
        
        def signon_block(node, statement)
          node.SIGNONMSGSRSV1 do |signonmsgrsv1|
            signonmsgrsv1.SONRS do |sonrs|
              sonrs.STATUS do |status|
                status.CODE "0"
                status.SEVERITY "INFO"
              end
              sonrs.DTSERVER time_to_ofx_dta(statement.server_response_time, true)
              sonrs.LANGUAGE statement.language
            end
            yield(signonmsgrsv1) if block_given?
          end
        end
        
        def ledger_balance_block(node, statement)
          node.LEDGERBAL do |ledgerbal|
            ledgerbal.BALAMT statement.ledger_balance
            ledgerbal.DTASOF time_to_ofx_dta(statement.date)
          end
        end
        
        def transaction_list(node, statement)
          node.BANKTRANLIST do |banktranlist|
            banktranlist.DTSTART time_to_ofx_dta(statement.start_date)
            banktranlist.DTEND time_to_ofx_dta(statement.end_date)
            yield(banktranlist) if block_given?
          end
        end
        
        def transaction_block(node, transaction)
          node.STMTTRN do |stmttrn|
            stmttrn.TRNTYPE generate_trntype(transaction.trntype)
            stmttrn.DTPOSTED time_to_ofx_dta(transaction.date)
            stmttrn.TRNAMT transaction.amount
            stmttrn.FITID transaction.fitid
            stmttrn.NAME transaction.name
            stmttrn.MEMO transaction.memo if transaction.has_memo?
          end
        end
        
        def serialise(builder, statement)
          builder.instruct!
          ofx_pi(builder)
          ofx_block(builder) do |ofx|
            signon_block(ofx, statement) do |signon|
              message_set_block(signon) do |message_set|
                statement_block(message_set, statement) do |stmnt|
                  statement.transactions.each do |transaction|
                    transaction_block(stmnt, transaction)
                  end
                end
              end
            end
          end
          builder
        end
      end
    end
  end
end
  