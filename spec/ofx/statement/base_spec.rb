require File.expand_path(File.dirname(__FILE__) + '/../../spec_helper')

describe OFX::Statement::Base do
  describe "instances" do
    before(:each) do
      @statement = OFX::Statement::Base.new
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
      
      describe "transactions" do
        it "should allow transactions to be appended" do
          mock_transaction = mock('Transaction')
          mock_transaction.expects(:statement=).with(@statement)
          
          @statement << mock_transaction
          @statement.transactions.should == [mock_transaction]
        end
        
        it "should default to []" do
          @statement.transactions.should == []
        end
        
        describe "generating FITIDs for transactions" do
          it "should generate a FITID which is unique, even for identical transactions" do
            @statement.date = Time.utc('2009', '3', '11')
            transaction = OFX::Statement::Transaction.new("-350.00", Time.utc('2009','3','8'), 'TEST TRANSACTION')
            transaction2 = OFX::Statement::Transaction.new("-350.00", Time.utc('2009','3','8'), 'TEST TRANSACTION')
            @statement << transaction
            @statement << transaction2
            
            @statement.fitid_for(transaction).should_not == @statement.fitid_for(transaction2)
          end
          
          it "should generate FITIDs which meet the field requirements for OFX" do
            @statement.date = Time.utc('2009', '3', '11')
            transaction = OFX::Statement::Transaction.new("-350.00", Time.utc('2009','3','8'), 'TEST TRANSACTION')
            @statement << transaction
            
            fitid = @statement.fitid_for(transaction)
            fitid.should match(/^[a-z0-9]+$/)
            (fitid.length < 254).should be_true
          end
        end
      end
    end
  end
end
