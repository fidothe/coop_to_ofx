require File.expand_path(File.dirname(__FILE__) + '/../../../spec_helper')

describe OFX::Statement::Output::CreditCard do
  describe "generating OFX" do
    before(:each) do
      @output = OFX::Statement::Output::CreditCard.new
    end
    
    describe "components" do
      before(:each) do
        @builder = Builder::XmlMarkup.new
      end
      
      describe "credit card message set wrapper" do
        it "should be able to generate the correct OFX root element" do
          @output.message_set_block(@builder)
          output = Hpricot(@builder.target!)
          
          output.at('/CREDITCARDMSGSETV1').should_not be_nil
        end
        
        it "should yield a child node builder so that document generation can continue" do
          @output.message_set_block(@builder) { |node| node.fnord }
          output = Hpricot(@builder.target!)
          
          output.at('/CREDITCARDMSGSETV1/fnord').should_not be_nil
        end
      end
      
      describe "credit card statement block" do
        before(:each) do
          @statement = stub('Statement', :start_date => Time.utc('2009', '1', '7', '12', '13', '14'), 
                                         :end_date => Time.utc('2009', '1', '8', '12', '13', '14'), 
                                         :date => Time.utc('2009', '1', '8', '12', '13', '14'),
                                         :currency => 'GBP', :account_number => "1234123412341234", 
                                         :available_credit => '305.00', :ledger_balance => "-1551.90")
        end
        
        it "should be able to generate the correct Statement block" do
          @output.statement_block(@builder, @statement)
          output = Hpricot(@builder.target!)
          
          output.at('/CCSTMTTRNRS/CCSTMTRS/CURDEF').should_not be_nil
          output.at('/CCSTMTTRNRS/CCSTMTRS/CURDEF').inner_text.should == "GBP"
          
          output.at('/CCSTMTTRNRS/CCSTMTRS/CCACCTFROM').should_not be_nil
          output.at('/CCSTMTTRNRS/CCSTMTRS/CCACCTFROM/ACCTID').inner_text.should == "1234123412341234"
          
          output.at('/CCSTMTTRNRS/CCSTMTRS/LEDGERBAL').should_not be_nil
          
          output.at('/CCSTMTTRNRS/CCSTMTRS/AVAILBAL').should_not be_nil
          output.at('/CCSTMTTRNRS/CCSTMTRS/AVAILBAL/BALAMT').inner_text.should == "305.00"
          output.at('/CCSTMTTRNRS/CCSTMTRS/AVAILBAL/DTASOF').inner_text.should == "20090108"
          
          output.at('/CCSTMTTRNRS/CCSTMTRS/BANKTRANLIST').should_not be_nil
        end
        
        it "should yield a child node builder so that document generation can continue" do
          @output.statement_block(@builder, @statement) { |node| node.fnord }
          output = Hpricot(@builder.target!)
          
          output.at('/CCSTMTTRNRS/CCSTMTRS/BANKTRANLIST/fnord').should_not be_nil
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
      statement << transaction
      
      output_doc = Hpricot(@output.serialise(statement))
      output_doc.search('/OFX/SIGNONMSGSRSV1/SONRS/STATUS/CODE').should_not be_empty
      output_doc.search('/OFX/SIGNONMSGSRSV1/CREDITCARDMSGSETV1/CCSTMTTRNRS/CCSTMTRS/BANKTRANLIST/STMTTRN/TRNAMT').should_not be_empty
    end
  end
end