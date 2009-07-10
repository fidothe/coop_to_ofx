require File.expand_path(File.dirname(__FILE__) + '/../spec_helper')

describe CoopScraper::Base do
  before(:each) do
    klass = Class.new
    klass.class_eval { include CoopScraper::Base }
    @instance = klass.new
  end
  
  describe "making Ruby dates from Co-op dates" do
    it "should be able to turn a DD/MM/YYYY string into a YYYYMMDD one" do
      @instance.coop_date_to_time('03/02/2009').should == Time.utc('2009', '2', '3')
    end
  end
end