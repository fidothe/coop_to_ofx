require File.expand_path(File.dirname(__FILE__) + '/../spec_helper')

describe CoopScraper::CreditCard do
  describe "parsing the html components" do
    def fixture_doc
      @fixture_doc ||= open(fixture_path('cc_statement_fixture.html')) { |f| Hpricot(f) }
    end
    
    def fixture_with_interest_line_doc
      @fixture_with_interest_line_doc ||= open(fixture_path('statement_with_interest_line_fixture.html')) { |f| Hpricot(f) }
    end
    
    def normal_transaction_fixture_doc
      @normal_transaction_fixture_doc ||= open(fixture_path('normal_transaction_fixture.html')) { |f| Hpricot(f) }
    end
    
    def payment_in_transaction_fixture_doc
      @payment_in_transaction_fixture_doc ||= open(fixture_path('payment_in_transaction_fixture.html')) { |f| Hpricot(f) }
    end
    
    def foreign_transaction_fixture_doc
      @foreign_transaction_fixture_doc ||= open(fixture_path('foreign_transaction_fixture.html')) { |f| Hpricot(f) }
    end
    
    describe "making Ruby dates from Co-op dates" do
      it "should be able to turn a DD/MM/YYYY string into a YYYYMMDD one" do
        CoopScraper::CreditCard.coop_date_to_time('03/02/2009').should == Time.utc('2009', '2', '3')
      end
    end
    
    it "should be able to extract the statement date" do
      CoopScraper::CreditCard.extract_statement_date(fixture_doc).should == Time.utc('2009', '2', '3')
    end
    
    it "should be able to extract the account (VISA card) number" do
      CoopScraper::CreditCard.extract_account_number(fixture_doc).should == '1234123412341234'
    end
    
    it "should be able to extract the statement balance" do
      CoopScraper::CreditCard.extract_statement_balance(fixture_doc).should == '-123.21'
    end
    
    it "should be able to extract the available credit" do
      CoopScraper::CreditCard.extract_available_credit(fixture_doc).should == '1000.00'
    end
    
    describe "extracting transactions" do
      it "should find the correct number of transactions" do
        CoopScraper::CreditCard.extract_transactions(fixture_doc).size.should == 57
      end
      
      it "should create OFX::Statement::Transaction objects for the transactions" do
        CoopScraper::CreditCard.extract_transactions(fixture_doc).first.should be_instance_of(OFX::Statement::Transaction)
      end
      
      describe "processing a normal transaction" do
        before(:each) do
          transactions = CoopScraper::CreditCard.extract_transactions(normal_transaction_fixture_doc)
          transactions.size.should == 1
          @transaction = transactions.first
        end
        
        it "should pull out the date" do
          @transaction.date.should == Time.utc('2009', '1', '6')
        end
        
        it "should pull out the amount" do
          @transaction.amount.should == '-23.00'
        end
        
        it "should pull out the details" do
          @transaction.name.should == 'SOME TRANSACTION HERE'
        end
      end
      
      describe "processing a transaction where money was put in" do
        before(:each) do
          transactions = CoopScraper::CreditCard.extract_transactions(payment_in_transaction_fixture_doc)
          transactions.size.should == 1
          @transaction = transactions.first
        end
        
        it "should pull out the date" do
          @transaction.date.should == Time.utc('2009', '1', '23')
        end
        
        it "should pull out the amount" do
          @transaction.amount.should == '500.00'
        end
        
        it "should pull out the details" do
          @transaction.name.should == 'PAYMENT -             THANK YOU     GB'
        end
      end
      
      describe "processing a transaction with an additional row for currency conversion" do
        before(:each) do
          transactions = CoopScraper::CreditCard.extract_transactions(foreign_transaction_fixture_doc)
          transactions.size.should == 1
          @transaction = transactions.first
        end
        
        it "should pull out the date" do
          @transaction.date.should == Time.utc('2009', '1', '8')
        end
        
        it "should pull out the amount" do
          @transaction.amount.should == '-27.13'
        end
        
        it "should pull out the details" do
          @transaction.name.should == 'TUFFMAIL              123-1234567'
        end
        
        it "should pull out the conversion details" do
          @transaction.memo.should == '##0000        40.00 USD @       1.4744'
        end
      end
      
      it "should ignore estimated interest lines" do
        transactions = CoopScraper::CreditCard.extract_transactions(fixture_with_interest_line_doc)
        transactions.size.should == 1
        transactions.first.should_not have_memo
      end
    end
  end
  
  describe "creating the statement object" do
    # def convert_statement(html_statement_io, server_response_time)
    #   doc = Hpricot(html_statement_io)
    #   
    #   account_number = extract_account_number(doc)
    #   statement_date = time_to_ofx_dta(extract_statement_date(doc))
    #   statement_balance = extract_statement_balance(doc)
    #   available_credit = extract_available_credit(doc)
    #   
    #   transactions = extract_transactions(doc)
    #   
    #   statement_start = transactions.first[:date]
    #   statement_end = transactions.last[:date]
    before(:each) do
      fixture = open(fixture_path('cc_statement_fixture.html'))
      @statement = CoopScraper::CreditCard.generate_statement(fixture, Time.utc('2009', '3', '6'))
    end
    
    it "should have the right server response time" do
      @statement.server_response_time.should == Time.utc('2009', '3', '6')
    end
    
    it "should the correct statement date" do
      @statement.date.should == Time.utc('2009', '2', '3')
    end
    
    it "should have the correct account number" do
      @statement.account_number.should == "1234123412341234"
    end
    
    it "should have the correct statement start date" do
      @statement.start_date.should == Time.utc('2009', '1', '5')
    end
    
    it "should have the correct statement end date" do
      @statement.end_date.should == Time.utc('2009', '2', '2')
    end
    
    it "should have the correct balance" do
      @statement.ledger_balance.should == "-123.21"
    end
    
    it "should have the correct amount of available credit" do
      @statement.available_credit.should == "1000.00"
    end
    
    it "should have the right number of transactions" do
      @statement.transactions.size.should == 57
    end
  end
end