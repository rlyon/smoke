require File.dirname(__FILE__) + '/spec_helper'

describe "Hash monkey: include_only?" do
  it "should return true if only the provided keys are found in the hash" do
    h = {:a => 0, :b => 1, :c => 2}
    h.include_only?(:a).should be_false
    h.include_only?(:a, :b).should be_false
    h.include_only?(:a, :b, :c).should be_true
    h.include_only?(:a, :b, :c, :d).should be_true
  end
end

describe "Hash monkey: include_only" do
  it "shouldn't raise exception if only the provided keys are found in the hash" do
    h = {:a => 0, :b => 1, :c => 3}
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
    h.has_key?(:error).should be_true
    error = h[:error]
    error.has_key?(:code).should be_true
    error[:code].should == "Hello"
    error.has_key?(:message).should be_true
    error[:message].should == "World"
    error.has_key?(:my_date).should be_true
    error[:my_date].should == "Now"
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