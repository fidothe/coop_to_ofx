require File.expand_path(File.dirname(__FILE__) + '/../../../spec_helper')

describe OFX::Statement::Output::SavingsAccount do
  describe "generating OFX" do
    before(:each) do
      @output = OFX::Statement::Output::SavingsAccount.new
    end
    describe "components" do
      before(:each) do
        @builder = Builder::XmlMarkup.new
      end
      
      describe "bank account message set wrapper" do
        it "should be able to generate the correct bank account message set element" do
          @output.message_set_block(@builder)
          output = Hpricot(@builder.target!)
          
          output.at('/BANKMSGSETV1').should_not be_nil
        end
        
        it "should yield a child node builder so that document generation can continue" do
          @output.message_set_block(@builder) { |node| node.fnord }
          output = Hpricot(@builder.target!)
          
          output.at('/BANKMSGSETV1/fnord').should_not be_nil
        end
      end
      
      describe "savings account statement block" do
        before(:each) do
          @statement = stub('Statement', :start_date => Time.utc('2009', '1', '7', '12', '13', '14'), 
                                         :end_date => Time.utc('2009', '1', '8', '12', '13', '14'), 
                                         :date => Time.utc('2009', '1', '8', '12', '13', '14'), 
                                         :currency => 'GBP', :account_number => "12341234", 
                                         :sort_code => '089273', :ledger_balance => "-1551.90")
        end
        
        it "should be able to generate the correct Statement block" do
          @output.statement_block(@builder, @statement)
          output = Hpricot(@builder.target!)
          
          output.at('/STMTTRNRS/STMTRS/CURDEF').should_not be_nil
          output.at('/STMTTRNRS/STMTRS/CURDEF').inner_text.should == "GBP"
          
          output.at('/STMTTRNRS/STMTRS/BANKACCTFROM').should_not be_nil
          output.at('/STMTTRNRS/STMTRS/BANKACCTFROM/BANKID').inner_text.should == "089273"
          output.at('/STMTTRNRS/STMTRS/BANKACCTFROM/ACCTID').inner_text.should == "12341234"
          output.at('/STMTTRNRS/STMTRS/BANKACCTFROM/ACCTTYPE').inner_text.should == "SAVINGS"
          
          output.at('/STMTTRNRS/STMTRS/LEDGERBAL').should_not be_nil
          
          output.at('/STMTTRNRS/STMTRS/BANKTRANLIST').should_not be_nil
        end
        
        it "should yield a child node builder so that document generation can continue" do
          @output.statement_block(@builder, @statement) { |node| node.fnord }
          output = Hpricot(@builder.target!)
          
          output.at('/STMTTRNRS/STMTRS/BANKTRANLIST/fnord').should_not be_nil
        end
      end

      it "should be able to generate a correct OFX file" do
        transaction = OFX::Statement::Transaction.new("-15.00", Time.utc('2009', '1', '5'), "COMP HSE FILE-DOM INTERNET GB")
        statement = OFX::Statement::SavingsAccount.new
        statement.server_response_time = Time.utc('2009', '2', '6', '18', '35', '56')
        statement.account_number = '12341234'
        statement.start_date = Time.utc('2009', '1', '1')
        statement.end_date = Time.utc('2009', '2', '3')
        statement.date = Time.utc('2009', '2', '3')
        statement.ledger_balance = "-1551.90"
        statement.sort_code = "089273"
        statement << transaction
        
        output_doc = Hpricot(@output.serialise(statement))
        output_doc.search('/OFX/SIGNONMSGSRSV1/SONRS/STATUS/CODE').should_not be_empty
        output_doc.search('/OFX/SIGNONMSGSRSV1/BANKMSGSETV1/STMTTRNRS/STMTRS/BANKTRANLIST/STMTTRN/TRNAMT').should_not be_empty
      end
    end
  end
end
