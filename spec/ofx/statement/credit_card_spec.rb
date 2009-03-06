require File.expand_path(File.dirname(__FILE__) + '/../../spec_helper')

describe OFX::Statement::CreditCard do
  before(:each) do
    @statement = OFX::Statement::CreditCard.new
  end
  
  describe "setting the data" do
    describe "server response time" do
      it "should allow the server response time to be set" do
        t = Time.now
        
        @statement.server_response_time = t
        @statement.server_response_time.should == t
      end
      
      it "should default to Time.now if it's not set" do
        t = Time.now
        Time.expects(:now).returns(t)
        
        @statement.server_response_time.should == t
      end
    end
    
    describe "language" do
      it "should allow the language to be set" do
        @statement.language = "FR"
        @statement.language.should == "FR"
      end
      
      it "should default to 'ENG' if not set" do
        @statement.language.should == "ENG"
      end
    end
    
    describe "currency" do
      it "should allow the currency to be set" do
        @statement.currency = 'USD'
        @statement.currency.should == 'USD'
      end

      it "should default to 'GBP' if not set" do
        @statement.currency.should == 'GBP'
      end
    end
    
    it "should allow the account number to be set" do
      @statement.account_number = '1234123412341234'
      @statement.account_number.should == '1234123412341234'
    end
    
    it "should allow the statement's start date to be set" do
      t = Time.now
      
      @statement.start_date = t
      @statement.start_date.should == t
    end
    
    it "should allow the statement's end date to be set" do
      t = Time.now
      
      @statement.end_date = t
      @statement.end_date.should == t
    end
    
    it "should statement's date to be set" do
      t = Time.now
      
      @statement.date = t
      @statement.date.should == t
    end
    
    it "should allow the statement's ledger balance to be set" do
      @statement.ledger_balance = "150.56"
      @statement.ledger_balance.should == "150.56"
    end
    
    it "should allow the statement's available credit amount to be set" do
      @statement.available_credit = "150.56"
      @statement.available_credit.should == "150.56"
    end
    
    describe "transactions" do
      it "should allow transactions to be set" do
        @statement.transactions = ['trn']
        @statement.transactions.should == ['trn']
      end
      
      it "should default to []" do
        @statement.transactions.should == []
      end
    end
  end
  
  describe "generating OFX" do
    it "should provide an XML builder object" do
      @statement.builder.should respond_to(:target!)
    end
    
    describe "components" do
      before(:each) do
        @builder = Builder::XmlMarkup.new
      end
      
      it "should be able to generate the right PI" do
        OFX::Statement::CreditCard.ofx_pi(@builder)
        pi = @builder.target!.strip
        pi.should match(/^<\?OFX/)
        pi.should match(/OFXHEADER="200"/)
        pi.should match(/VERSION="203"/)
        pi.should match(/SECURITY="NONE"/)
        pi.should match(/OLDFILEUID="NONE"/)
        pi.should match(/NEWFILEUID="NONE"/)
      end
      
      describe "OFX wrapper" do
        it "should be able to generate the correct OFX root element" do
          OFX::Statement::CreditCard.ofx_block(@builder)
          @builder.target!.strip.should == "<OFX/>"
        end
        
        it "should yield a child node builder so that document generation can continue" do
          OFX::Statement::CreditCard.ofx_block(@builder) { |node| node.fnord }
          @builder.target!.strip.should == "<OFX><fnord/></OFX>"
        end
      end
      
      describe "signon block" do
        before(:each) do
          @t = Time.utc('2009', '1', '8', '12', '13', '14')
        end
        
        it "should be able to generate a sensible Signon Message Set, with Signon response block" do
          OFX::Statement::CreditCard.signon_block(@builder, @t, 'ENG')
          @builder.target!.strip.should == "<SIGNONMSGSRSV1><SONRS><STATUS><CODE>0</CODE><SEVERITY>INFO</SEVERITY></STATUS><DTSERVER>20090108121314</DTSERVER><LANGUAGE>ENG</LANGUAGE></SONRS></SIGNONMSGSRSV1>"
        end
        
        it "should yield a child node builder so that document generation can continue" do
          OFX::Statement::CreditCard.signon_block(@builder, @t, 'ENG') { |node| node.fnord }
          @builder.target!.strip.should == "<SIGNONMSGSRSV1><SONRS><STATUS><CODE>0</CODE><SEVERITY>INFO</SEVERITY></STATUS><DTSERVER>20090108121314</DTSERVER><LANGUAGE>ENG</LANGUAGE></SONRS><fnord/></SIGNONMSGSRSV1>"
        end
      end
      
      describe "credit card message set wrapper" do
        it "should be able to generate the correct OFX root element" do
          OFX::Statement::CreditCard.message_set_block(@builder)
          @builder.target!.strip.should == "<CREDITCARDMSGSETV1/>"
        end
        
        it "should yield a child node builder so that document generation can continue" do
          OFX::Statement::CreditCard.message_set_block(@builder) { |node| node.fnord }
          @builder.target!.strip.should == "<CREDITCARDMSGSETV1><fnord/></CREDITCARDMSGSETV1>"
        end
      end
      
      describe "credit card statement block" do
        before(:each) do
          @t_start = Time.utc('2009', '1', '7', '12', '13', '14')
          @t_end = Time.utc('2009', '1', '8', '12', '13', '14')
          @currency = "GBP"
          @account_number = "1234123412341234"
          @statement_ledger_balance = "-1551.90"
          @available_credit = "305.00"
        end
        
        it "should be able to generate the correct Statement block" do
          OFX::Statement::CreditCard.statement_block(@builder, @account_number, @t_end, @t_start, @t_end, @currency, @statement_ledger_balance, @available_credit)
          @builder.target!.strip.should == "<CCSTMTTRNRS><CCSTMTRS><CURDEF>GBP</CURDEF><CCACCTFROM><ACCTID>1234123412341234</ACCTID></CCACCTFROM><BANKTRANLIST><DTSTART>20090107</DTSTART><DTEND>20090108</DTEND></BANKTRANLIST><LEDGERBAL><BALAMT>-1551.90</BALAMT><DTASOF>20090108</DTASOF></LEDGERBAL><AVAILBAL><BALAMT>305.00</BALAMT><DTASOF>20090108</DTASOF></AVAILBAL></CCSTMTRS></CCSTMTTRNRS>"
        end
        
        it "should yield a child node builder so that document generation can continue" do
          OFX::Statement::CreditCard.statement_block(@builder, @account_number, @t_end, @t_start, @t_end, @currency, @statement_ledger_balance, @available_credit) { |node| node.fnord }
          @builder.target!.strip.should == "<CCSTMTTRNRS><CCSTMTRS><CURDEF>GBP</CURDEF><CCACCTFROM><ACCTID>1234123412341234</ACCTID></CCACCTFROM><BANKTRANLIST><DTSTART>20090107</DTSTART><DTEND>20090108</DTEND><fnord/></BANKTRANLIST><LEDGERBAL><BALAMT>-1551.90</BALAMT><DTASOF>20090108</DTASOF></LEDGERBAL><AVAILBAL><BALAMT>305.00</BALAMT><DTASOF>20090108</DTASOF></AVAILBAL></CCSTMTRS></CCSTMTTRNRS>"
        end
      end
      
      describe "transaction block" do
        before(:each) do
          @t = Time.utc('2009', '1', '8', '12', '13', '14')
          OFX::Statement::CreditCard.stubs(:fitid_hash).returns({})
        end
        
        it "should be able to generate a transaction block from a debit transaction object without currency conversion details" do
          transaction = OFX::Statement::Transaction.new("-350.00", @t, "A nice thing wot I bought")
          OFX::Statement::CreditCard.transaction_block(@builder, transaction)
          @builder.target!.strip.should == "<STMTTRN><TRNTYPE>DEBIT</TRNTYPE><DTPOSTED>20090108</DTPOSTED><TRNAMT>-350.00</TRNAMT><FITID>200901081</FITID><NAME>A nice thing wot I bought</NAME></STMTTRN>"
        end
        
        it "should be able to generate a transaction block from a credit transaction object without currency conversion" do
          transaction = OFX::Statement::Transaction.new("350.00", @t, "A nice sum wot I was given")
          OFX::Statement::CreditCard.transaction_block(@builder, transaction)
          @builder.target!.strip.should == "<STMTTRN><TRNTYPE>CREDIT</TRNTYPE><DTPOSTED>20090108</DTPOSTED><TRNAMT>350.00</TRNAMT><FITID>200901081</FITID><NAME>A nice sum wot I was given</NAME></STMTTRN>"
        end
        
        it "should be able to generate a transaction block from a debit transaction object with a memo / currency conversion info" do
          transaction = OFX::Statement::Transaction.new("-350.00", @t, "A nice thing wot I bought", "plenty USD wonga")
          OFX::Statement::CreditCard.transaction_block(@builder, transaction)
          @builder.target!.strip.should == "<STMTTRN><TRNTYPE>DEBIT</TRNTYPE><DTPOSTED>20090108</DTPOSTED><TRNAMT>-350.00</TRNAMT><FITID>200901081</FITID><NAME>A nice thing wot I bought</NAME><MEMO>plenty USD wonga</MEMO></STMTTRN>"
        end
      end
    end
    
    it "should be able to generate a correct OFX file" do
      transaction = OFX::Statement::Transaction.new("-15.00", Time.utc('2009', '1', '5'), "COMP HSE FILE-DOM INTERNET GB")
      statement = OFX::Statement::CreditCard.new
      statement.server_response_time = Time.utc('2009', '2', '6', '18', '35', '56')
      statement.account_number = '1234123412341234'
      statement.start_date = Time.utc('2009', '1', '1')
      statement.end_date = Time.utc('2009', '2', '3')
      statement.date = Time.utc('2009', '2', '3')
      statement.ledger_balance = "-1551.90"
      statement.available_credit = "305.00"
      statement.transactions << transaction
      
      output_doc = Hpricot(statement.serialise)
      output_doc.search('/OFX/SIGNONMSGSRSV1/SONRS/STATUS/CODE').should_not be_empty
      output_doc.search('/OFX/SIGNONMSGSRSV1/CREDITCARDMSGSETV1/CCSTMTTRNRS/CCSTMTRS/BANKTRANLIST/STMTTRN/TRNAMT').should_not be_empty
    end
  end
end
