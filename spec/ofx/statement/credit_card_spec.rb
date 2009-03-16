require File.expand_path(File.dirname(__FILE__) + '/../../spec_helper')

describe OFX::Statement::CreditCard do
  before(:each) do
    @statement = OFX::Statement::CreditCard.new
  end
  
  describe "setting the data" do
    it "should allow the statement's available credit amount to be set" do
      @statement.available_credit = "150.56"
      @statement.available_credit.should == "150.56"
    end
  end
  
  describe "output" do
    it "should use the right output generator" do
      @statement.output.should == OFX::Statement::Output::CreditCard
    end
  end
end
