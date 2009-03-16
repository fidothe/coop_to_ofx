require File.expand_path(File.dirname(__FILE__) + '/../spec_helper')

describe CoopScraper::CurrentAccount do
  def fixture_path(fixture_file_name)
    full_fixture_path('current_account', fixture_file_name)
  end
  
  describe "parsing the html components" do
    def fixture_doc(name = 'current_account_fixture.html')
      open(fixture_path(name)) { |f| Hpricot(f) }
    end
    
    def normal_transaction_fixture_doc
      fixture_doc('normal_transaction_fixture.html')
    end
    
    def payment_in_transaction_fixture_doc
      fixture_doc('payment_in_transaction_fixture.html')
    end
    
    def no_transactions_fixture_doc
      fixture_doc('no_transactions_fixture.html')
    end
    
    it "should be able to extract the statement date" do
      CoopScraper::CurrentAccount.extract_statement_date(fixture_doc).should == Time.utc('2008', '10', '3')
    end
    
    it "should be able to extract the account number" do
      CoopScraper::CurrentAccount.extract_account_number(fixture_doc).should == "12341234"
    end
    
    it "should be able to extract the sort code" do
      CoopScraper::CurrentAccount.extract_sort_code(fixture_doc).should == "089273"
    end
    
    describe "transactions" do
      it "should find the correct number of transactions" do
        CoopScraper::CurrentAccount.extract_transactions(fixture_doc).size.should == 7
      end
      
      it "should create OFX::Statement::Transaction objects for the transactions" do
        CoopScraper::CurrentAccount.extract_transactions(fixture_doc).first.should be_instance_of(OFX::Statement::Transaction)
      end
      
      describe "processing a normal transaction" do
        before(:all) do
          transactions = CoopScraper::CurrentAccount.extract_transactions(normal_transaction_fixture_doc)
          transactions.size.should == 1
          @transaction = transactions.first
        end
        
        it "should pull out the date" do
          @transaction.date.should == Time.utc('2008', '9', '29')
        end
        
        it "should pull out the amount" do
          @transaction.amount.should == '-20.00'
        end
        
        it "should pull out the details" do
          @transaction.name.should == 'LINK    10:51SEP28'
        end
      end
      
      describe "processing a transaction where money was put in" do
        before(:all) do
          transactions = CoopScraper::CurrentAccount.extract_transactions(payment_in_transaction_fixture_doc)
          transactions.size.should == 1
          @transaction = transactions.first
        end
        
        it "should pull out the date" do
          @transaction.date.should == Time.utc('2008', '10', '3')
        end
        
        it "should pull out the amount" do
          @transaction.amount.should == '200.00'
        end
        
        it "should pull out the details" do
          @transaction.name.should == 'SOME MONEY'
        end
      end
      
      describe "processing a statement where no transactions occurred" do
        before(:each) do
          @transactions = CoopScraper::CurrentAccount.extract_transactions(no_transactions_fixture_doc)
        end
        
        it "should not find any transactions" do
          @transactions.should be_empty
        end
      end
      
      describe "processing transactions with non-default transaction types" do
        it "should be able to pull out a debit interest transaction" do
          transactions = CoopScraper::CurrentAccount.
            extract_transactions(fixture_doc('debit_interest_transaction_fixture.html'))
          
          transactions.first.trntype.should == :interest
        end
        
        it "should be able to pull out a service charge transaction" do
          transactions = CoopScraper::CurrentAccount.
            extract_transactions(fixture_doc('service_charge_transaction_fixture.html'))
          
          transactions.first.trntype.should == :service_charge
        end
        
        it "should be able to pull out a transfer transaction" do
          transactions = CoopScraper::CurrentAccount.
            extract_transactions(fixture_doc('transfer_transaction_fixture.html'))
          
          transactions.first.trntype.should == :transfer
        end
        
        it "should be able to pull out a cash point transaction" do
          transactions = CoopScraper::CurrentAccount.
            extract_transactions(fixture_doc('cash_point_transaction_fixture.html'))
          
          transactions.first.trntype.should == :atm
        end
      end
    end
    
    it "should be able to extract the closing balance" do
      CoopScraper::CurrentAccount.extract_closing_balance(fixture_doc).should == "219.92"
    end
    
    it "should be able to extract the statement start date" do
      CoopScraper::CurrentAccount.extract_statement_start_date(fixture_doc).should == Time.utc('2008', '9', '29')
    end
    
    describe "generating the statement" do
      it "should create a statement object okay" do
        fixture = open(fixture_path('current_account_fixture.html'))
        mock_statement = mock('Statement')
        OFX::Statement::CurrentAccount.expects(:new).returns(mock_statement)
        
        mock_statement.expects(:server_response_time=).with(Time.utc('2009', '3', '6'))
        mock_statement.expects(:date=).with(Time.utc('2008', '10', '3'))
        mock_statement.expects(:sort_code=).with('089273')
        mock_statement.expects(:account_number=).with('12341234')
        mock_statement.expects(:start_date=).with(Time.utc('2008', '9', '29'))
        mock_statement.expects(:end_date=).with(Time.utc('2008', '10', '3'))
        mock_statement.expects(:ledger_balance=).with("219.92")
        mock_statement.expects(:<<).at_least_once.with { |arg| arg.respond_to?(:amount) }
        
        CoopScraper::CurrentAccount.generate_statement(fixture, Time.utc('2009', '3', '6'))
      end
    end
  end
end
