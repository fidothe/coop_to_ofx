require File.expand_path(File.dirname(__FILE__) + '/../../../spec_helper')

describe OFX::Statement::Output::Base do
  before(:all) do
    klass = Class.new
    klass.class_eval { include OFX::Statement::Output::Base }
    @base = klass.new
  end
  
  describe "outputting OFX" do
    describe "making OFX datetimes from Time objects" do
      it "should be able to turn a Time object into a YYYYMMDD string" do
        @base.time_to_ofx_dta(Time.utc('2009', '02', '03')).should == '20090203'
      end
      
      it "should be able to turn a Time object into a YYYYMMDDHHMMSS string" do
        @base.time_to_ofx_dta(Time.utc('2009', '02', '03', '14', '26', '15'), true).should == '20090203142615'
      end
    end
    
    describe "FITIDs" do
      it "should use an invocation-persistent store to ensure FITID uniqueness and repeatability" do
        @base.fitid_hash.should == @base.fitid_hash
      end
      
      describe "generating" do
        before(:each) do
          @fitid_hash = {}
          @base.stubs(:fitid_hash).returns(@fitid_hash)
        end
        
        it "should generate a FITID based on the date of the transaction" do
          @base.generate_fitid(Time.utc('2009', '2', '3')).should == '200902031'
        end
      
        it "should generate sequential FITIDs for two transaction on the same date" do
          @base.generate_fitid(Time.utc('2009', '2', '3')).should == '200902031'
          @base.generate_fitid(Time.utc('2009', '2', '3')).should == '200902032'
        end
      end
    end
    
    describe "TRNTYPE" do
      {
        :debit => "DEBIT", :credit => "CREDIT", :interest => "INT", :dividend => "DIV",
        :fee => "FEE", :service_charge => "SRVCHG", :deposit => "DEP", :atm => "ATM", 
        :point_of_sale => "POS", :transfer => "XFER", :cheque => "CHECK", :check => "CHECK",
        :payment => "PAYMENT", :cash => "CASH", :direct_deposit => "DIRECTDEP",
        :direct_debit => "DIRECTDEBIT", :repeating_payment => "REPEATPMT", 
        :standing_order => "REPEATPMT", :other => "OTHER"
      }.each do |input, expected|
        it "should return #{expected} for a trntype of #{input.inspect}" do
          @base.generate_trntype(input).should == expected
        end
      end
    end
    
    describe "components" do
      before(:each) do
        @builder = Builder::XmlMarkup.new
      end
      
      it "should be able to generate the right PI" do
        @base.ofx_pi(@builder)
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
          @base.ofx_block(@builder)
          output = Hpricot(@builder.target!)
          
          output.at('/OFX').should_not be_nil
        end
        
        it "should yield a child node builder so that document generation can continue" do
          @base.ofx_block(@builder) { |node| node.fnord }
          output = Hpricot(@builder.target!)
          
          output.at('/OFX/fnord').should_not be_nil
        end
      end
      
      describe "signon block" do
        before(:each) do
          @t = Time.utc('2009', '1', '8', '12', '13', '14')
          @statement = stub('Statement', :server_response_time => @t, :language => 'ENG')
        end
        
        it "should be able to generate a sensible Signon Message Set, with Signon response block" do
          
          @base.signon_block(@builder, @statement)
          output = Hpricot(@builder.target!)
          
          output.at('/SIGNONMSGSRSV1/SONRS').should_not be_nil
          output.at('/SIGNONMSGSRSV1/SONRS/STATUS/CODE').inner_text.should == '0'
          output.at('/SIGNONMSGSRSV1/SONRS/STATUS/SEVERITY').inner_text.should == 'INFO'
          output.at('/SIGNONMSGSRSV1/SONRS/DTSERVER').inner_text.should == '20090108121314'
          output.at('/SIGNONMSGSRSV1/SONRS/LANGUAGE').inner_text.should == 'ENG'
        end
        
        it "should yield a child node builder so that document generation can continue" do
          @base.signon_block(@builder, @statement) { |node| node.fnord }
          output = Hpricot(@builder.target!)
          
          output.at('/SIGNONMSGSRSV1/fnord').should_not be_nil
        end
      end
      
      describe "ledger balance block" do
        it "should produce the right bits for a ledger balance block" do
          statement = stub('Statement', :ledger_balance => '350.00', :date => Time.utc('2009', '2', '3'))
          @base.ledger_balance_block(@builder, statement)
          output = Hpricot(@builder.target!)
          
          output.at('/LEDGERBAL/BALAMT').inner_text.should == "350.00"
          output.at('/LEDGERBAL/DTASOF').inner_text.should == "20090203"
        end
      end
      
      describe "transaction list block" do
        before(:each) do
          @t = Time.utc('2009', '1', '8', '12', '13', '14')
          @t_end = Time.utc('2009', '1', '9', '12', '13', '14')
          @statement = stub('Statement', :start_date => @t, :end_date => @t_end)
          @base.stubs(:fitid_hash).returns({})
        end
        
        it "should generate a block with the right values" do
          @base.transaction_list(@builder, @statement)
          output = Hpricot(@builder.target!)
          
          output.at('/BANKTRANLIST/DTSTART').inner_text.should == "20090108"
          output.at('/BANKTRANLIST/DTEND').inner_text.should == "20090109"
        end
        
        it "should should yield for child node generation in the right place" do
          @base.transaction_list(@builder, @statement) { |child| child.fnord }
          output = Hpricot(@builder.target!)
          
          output.at('/BANKTRANLIST/fnord').should_not be_nil
        end
      end
      
      describe "transaction block" do
        before(:each) do
          @t = Time.utc('2009', '1', '8', '12', '13', '14')
          @base.stubs(:fitid_hash).returns({})
        end
        
        it "should be able to generate a transaction block from a debit transaction object without currency conversion details" do
          transaction = OFX::Statement::Transaction.new("-350.00", @t, "A nice thing wot I bought")
          transaction.stubs(:fitid).returns("PROPER:FIT:ID")
          @base.transaction_block(@builder, transaction)
          output = Hpricot(@builder.target!)
          
          output.at('/STMTTRN/TRNTYPE').inner_text.should == "DEBIT"
          output.at('/STMTTRN/DTPOSTED').inner_text.should == "20090108"
          output.at('/STMTTRN/TRNAMT').inner_text.should == "-350.00"
          output.at('/STMTTRN/FITID').inner_text.should == "PROPER:FIT:ID"
          output.at('/STMTTRN/NAME').inner_text.should == "A nice thing wot I bought"
        end
        
        it "should be able to generate a transaction block from a credit transaction object without currency conversion" do
          transaction = OFX::Statement::Transaction.new("350.00", @t, "A nice sum wot I was given")
          transaction.stubs(:fitid).returns("PROPER:FIT:ID")
          @base.transaction_block(@builder, transaction)
          output = Hpricot(@builder.target!)
          
          output.at('/STMTTRN/TRNTYPE').inner_text.should == "CREDIT"
          output.at('/STMTTRN/DTPOSTED').inner_text.should == "20090108"
          output.at('/STMTTRN/TRNAMT').inner_text.should == "350.00"
          output.at('/STMTTRN/FITID').inner_text.should == "PROPER:FIT:ID"
          output.at('/STMTTRN/NAME').inner_text.should == "A nice sum wot I was given"
        end
        
        it "should be able to generate a transaction block from a debit transaction object with a memo / currency conversion info" do
          transaction = OFX::Statement::Transaction.new("-350.00", @t, "A nice thing wot I bought", {:memo => "plenty USD wonga"})
          transaction.stubs(:fitid).returns("PROPER:FIT:ID")
          @base.transaction_block(@builder, transaction)
          output = Hpricot(@builder.target!)
          
          output.at('/STMTTRN/TRNTYPE').inner_text.should == "DEBIT"
          output.at('/STMTTRN/DTPOSTED').inner_text.should == "20090108"
          output.at('/STMTTRN/TRNAMT').inner_text.should == "-350.00"
          output.at('/STMTTRN/FITID').inner_text.should == "PROPER:FIT:ID"
          output.at('/STMTTRN/NAME').inner_text.should == "A nice thing wot I bought"
          output.at('/STMTTRN/MEMO').inner_text.should == "plenty USD wonga"
        end
      end
    end
  end
end