require File.expand_path(File.dirname(__FILE__) + '/../../spec_helper')

describe OFX::Statement::Transaction do
  describe "instantiating" do
    it "should require amount, date, details, memo" do
      OFX::Statement::Transaction.new("350", Time.now, "Details", "Memo").should be_instance_of(OFX::Statement::Transaction)
    end
  end
  
  describe "instances" do
    before(:each) do
      @t = Time.now
      @transaction = OFX::Statement::Transaction.new("350", @t, "Details", "Memo")
    end
    
    it "should report its amount" do
      @transaction.amount.should == "350"
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
    
    describe "memo" do
      it "should report that it has a memo" do
        @transaction.has_memo?.should be_true
      end
      
      it "should report that it does not have a memo" do
        transaction = OFX::Statement::Transaction.new("350", @t, "Details")
        transaction.has_memo?.should be_false
      end
    end
  end
end