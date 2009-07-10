require File.expand_path(File.dirname(__FILE__) + '/../../../spec_helper')

describe OFX::Statement::Output::Builder do
  describe OFX::Statement::Output::Builder::OFX2 do
    it "should generate the proper OFX 2 XML declaration stuff when asked" do
      builder = OFX::Statement::Output::Builder::OFX2.new(:indent => 2)
      builder.ofx_stanza!
      result = builder.target!
      result.should =~ /<\?xml version="1.0" encoding="UTF-8"\?>/
      result.should =~ /<\?OFX (?:(?:OLDFILEUID="NONE"|NEWFILEUID="NONE"|OFXHEADER="200"|VERSION="203"|SECURITY="NONE") ?)+\?>/
    end
  end
  
  describe OFX::Statement::Output::Builder::OFX1 do
    it "should generate the proper OFX 1 SGML header stuff when asked" do
      builder = OFX::Statement::Output::Builder::OFX1.new(:indent => 2)
      builder.ofx_stanza!
      result = builder.target!
      result.should == <<-EOH
OFXHEADER:100
DATA:OFXSGML
VERSION:103
SECURITY:NONE
ENCODING:USASCII
CHARSET:NONE
COMPRESSION:NONE
OLDFILEUID:NONE
NEWFILEUID:NONE
EOH
    end
    
    it "should generate empty tags without the trailing slash" do
      builder = OFX::Statement::Output::Builder::OFX1.new
      builder.my_tag
      builder.target!.should == "<my_tag>"
    end
  end
end