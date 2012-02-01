require File.dirname(__FILE__) + '/spec_helper'

describe "Hash monkey: include_only?" do
  it "should return true if only the provided keys are found in the hash" do
    h = {:a => 0, :b => 1, :c => 2}
    {}.include_only?(:a).should be_true
    h.include_only?(:a).should be_false
    h.include_only?(:a, :b).should be_false
    h.include_only?(:a, :b, :c).should be_true
    h.include_only?(:a, :b, :c, :d).should be_true
  end
end


describe "Hash monkey: stringify keys" do
  it "should turn symbols into key" do
    h = {:a => 0, :b => 1, :c => 2}
    h.stringify_keys
    h.keys.size.should == 3
    h.has_key?(:a).should be_false
    h.has_key?(:b).should be_false
    h.has_key?(:c).should be_false
    h.has_key?('a').should be_true
    h.has_key?('b').should be_true
    h.has_key?('c').should be_true
  end
end

describe "Hash monkey: include_only" do
  it "shouldn't raise exception if only the provided keys are found in the hash" do
    h = {:a => 0, :b => 1, :c => 3}
    expect { {}.include_only(:a) }.to_not raise_error
    expect { h.include_only(:a) }.to raise_error
    expect { h.include_only(:a, :b) }.to raise_error
    expect { h.include_only(:a, :b, :c) }.to_not raise_error
    expect { h.include_only(:a, :b, :c, :d) }.to_not raise_error
  end
end

describe "Hash monkey: from_xml_string" do
  it "should create a hash of symbol => values" do
    xml = "<Error><Code>Hello</Code><Message>World</Message><MyDate>Now</MyDate></Error>"
    h = Hash.from_xml_string(xml)
    h.has_key?('Error').should be_true
    error = h['Error']
    error.has_key?('Code').should be_true
    error['Code'].should == "Hello"
    error.has_key?('Message').should be_true
    error['Message'].should == "World"
    error.has_key?('MyDate').should be_true
    error['MyDate'].should == "Now"
  end
  
  it "should raise exception on invalid xml" do
    xml = "<Error><Code>Hello</Code><Message>World</Message><MyDate>Now</BADTAG></Error>"
    expect { h = Hash.from_xml_string(xml) ; puts h.inspect }.to raise_error
  end
  
  it "should parse attributes" do
    xml = "<Tag attr=\"hello world\">Hello</Tag>"
    h = Hash.from_xml_string(xml)
    tag = h['Tag']
    tag.has_key?('attr')
    tag['attr'].should == "hello world"
    tag['text'].should == "Hello"
  end
  
  it "should handle multiple nested entries correctly" do
    xml = "<List><Item><Name>one</Name><Type>this</Type></Item><Item><Name>two</Name><Type>this</Type></Item><Item><Name>three</Name><Type>this</Type></Item></List>"
    h = Hash.from_xml_string(xml)
    list = h['List']
    list.has_key?('Item').should be_true
    list['Item'].length.should == 3
  end
end

describe "String monkey: hex" do
  it "shouldn't accept shitty args" do
    expect { String.hex(:length => 100, :case => :upper, :bad => 'yep') }.to raise_error
  end
  
  it "should return an upper case hex string" do
    s = String.hex(:length => 100, :case => :upper)
    (s =~ /^[abcdef0-9]+$/).should be_nil
    (s =~ /^[ABCDEF0-9]+$/).should >= 0
  end
  
  it "should return a lower case hex string" do
    s = String.hex(:length => 100, :case => :lower)
    (s =~ /^[abcdef0-9]+$/).should >= 0
    (s =~ /^[ABCDEF0-9]+$/).should be_nil
  end
end

describe "String monkey: random" do
  it "should return an exception if an invalid option is passed" do
    expect { String.random(:length => 100, :bad => 'yep') }.to raise_error
  end
  
  it "should return a alpha only string" do
    s = String.random(:length => 100, :charset => :alpha)
    (s =~ /^[a-zA-Z]+$/).should >= 0
    (s =~ /^[0-9]+$/).should be_nil
  end
  
  it "should return a uppercase alphanumeric only string" do
    s = String.random(:length => 100, :charset => :alnum_upper)
    (s =~ /^[0-9A-Z]+$/).should >= 0
    (s =~ /^[a-z]+$/).should be_nil
  end
end

describe "Fixnum monkey: " do
  it "days should return n number of days in the future" do
    Time.stubs(:now).returns(Time.mktime(1970,1,1,0,0,0))
    10.days.should == Time.mktime(1970,1,11,0,0,0)
  end
  
  it "hours should return n number of hours in the future" do
    Time.stubs(:now).returns(Time.mktime(1970,1,1,0,0,0))
    10.hours.should == Time.mktime(1970,1,1,10,0,0)
  end
  
  it "weeks should return n number of weeks in the future" do
    Time.stubs(:now).returns(Time.mktime(1970,1,1,0,0,0))
    2.weeks.should == Time.mktime(1970,1,15,0,0,0)
  end
  
  it "months should return n number of months in the future" do
    Time.stubs(:now).returns(Time.mktime(1970,1,1,0,0,0))
    15.months.should == Time.mktime(1971,4,1,0,0,0)
  end
  
  it "years should return n number of years in the future" do
    Time.stubs(:now).returns(Time.mktime(1970,1,1,0,0,0))
    15.years.should == Time.mktime(1985,1,1,0,0,0)
  end
end

describe "Time monkey: " do
  it "to_z should return the correct value" do
    # Converts to gmt
    Time.stubs(:now).returns(Time.mktime(1970,1,1,0,0,0))
    Time.now.to_z.should == "1970-01-01T08:00:00.000Z"
  end
  
  it "to_web should return the correct value" do
    # Converts to gmt
    Time.stubs(:now).returns(Time.mktime(1970,1,1,0,0,0))
    Time.now.to_web.should == "Thu, 01 Jan 1970 08:00:00 +0000"
  end
  
  it "to_yearmonth should return the correct value" do
    # Converts to gmt
    Time.stubs(:now).returns(Time.mktime(1970,1,1,0,0,0))
    Time.now.to_yearmonth.should == "197001"
  end
end
