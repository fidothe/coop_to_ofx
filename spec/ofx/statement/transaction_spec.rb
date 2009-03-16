require File.expand_path(File.dirname(__FILE__) + '/../../spec_helper')

describe OFX::Statement::Transaction do
  describe "instantiating" do
    it "should require amount, date, details, and allow an options hash" do
      OFX::Statement::Transaction.new("350", Time.now, "Details", {:memo => "Memo"}).should be_instance_of(OFX::Statement::Transaction)
    end
  end
  
  describe "instances" do
    before(:each) do
      @t = Time.now
      @transaction = OFX::Statement::Transaction.new("350.00", @t, "Details", {:memo => "Memo"})
    end
    
    it "should report its amount" do
      @transaction.amount.should == "350.00"
    end
    
    it "should report its date" do
      @transaction.date.should == @t
    end
    
    it "should report its name" do
      @transaction.name.should == "Details"
    end
    
    it "should report its memo" do
      @transaction.memo.should == "Memo"
    end
    
    it "should should allow its statement to be set and retrieved" do
      @transaction.statement = :statement
      @transaction.statement.should == :statement
    end
    
    it "should be able to get a sane FITID" do
      mock_statement = mock('Statement')
      @transaction.stubs(:statement).returns(mock_statement)
      
      mock_statement.expects(:fitid_for).with(@transaction).returns(:sane_fitid)
      
      @transaction.fitid.should == :sane_fitid
    end
    
    describe "memo" do
      it "should report that it has a memo" do
        @transaction.has_memo?.should be_true
      end
      
      it "should report that it does not have a memo" do
        transaction = OFX::Statement::Transaction.new("350.00", @t, "Details")
        
        transaction.has_memo?.should be_false
      end
    end
    
    describe "basic transaction types" do
      it "should default to :credit for a positive amount" do
        @transaction.trntype.should == :credit
      end
      
      it "should default to debit for a negative amount" do
        transaction = OFX::Statement::Transaction.new("-350.00", @t, "Details")
        
        transaction.trntype.should == :debit
      end
      
      it "should allow the type to be set in the options hash" do
        transaction = OFX::Statement::Transaction.new("-350.00", @t, "Details", :trntype => :credit)
        
        transaction.trntype.should == :credit
      end
    end
  end
end