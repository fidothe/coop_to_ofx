require File.expand_path(File.dirname(__FILE__) + '/../../spec_helper')

describe OFX::Statement::CurrentAccount do
  before(:each) do
    @statement = OFX::Statement::CurrentAccount.new
  end
  
  describe "setting the data" do
    it "should allow the statement's sort code to be set" do
      @statement.sort_code = "089273"
      @statement.sort_code.should == "089273"
    end
  end
  
  describe "output" do
    it "should use the right output generator" do
      @statement.output.should == OFX::Statement::Output::CurrentAccount
    end
  end
end