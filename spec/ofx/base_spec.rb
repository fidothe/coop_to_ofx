require File.expand_path(File.dirname(__FILE__) + '/../spec_helper')

describe OFX::Base do
  describe "outputting OFX" do
    describe "making OFX datetimes from Time objects" do
      it "should be able to turn a Time object into a YYYYMMDD string" do
        OFX::Base.time_to_ofx_dta(Time.utc('2009', '02', '03')).should == '20090203'
      end
      
      it "should be able to turn a Time object into a YYYYMMDDHHMMSS string" do
        OFX::Base.time_to_ofx_dta(Time.utc('2009', '02', '03', '14', '26', '15'), true).should == '20090203142615'
      end
    end
    
    describe "FITIDs" do
      it "should use an invocation-persistent store to ensure FITID uniqueness and repeatability" do
        OFX::Base.fitid_hash.should == OFX::Base.fitid_hash
      end
      
      describe "generating" do
        before(:each) do
          @fitid_hash = {}
          OFX::Base.stubs(:fitid_hash).returns(@fitid_hash)
        end
        
        it "should generate a FITID based on the date of the transaction" do
          OFX::Base.generate_fitid(Time.utc('2009', '2', '3')).should == '200902031'
        end
      
        it "should generate sequential FITIDs for two transaction on the same date" do
          OFX::Base.generate_fitid(Time.utc('2009', '2', '3')).should == '200902031'
          OFX::Base.generate_fitid(Time.utc('2009', '2', '3')).should == '200902032'
        end
      end
    end
    
    describe "TRNTYPE" do
      it "should return DEBIT for a negative transaction" do
        OFX::Base.generate_trntype('-100').should == 'DEBIT'
      end
      
      it "should return CREDIT for a positive transaction" do
        OFX::Base.generate_trntype('100').should == 'CREDIT'
      end
    end
  end
end
