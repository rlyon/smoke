require File.dirname(__FILE__) + '/spec_helper'

describe "Smoke::User" do
  
  before(:each) do
    @user = Smoke::User.new(:username => "mocky")
  end
  
  after(:each) do
    Smoke.database.collection('user').remove({})
    Smoke.database.collection('smbucket').remove({})
  end
  
  it "should respond to :id" do
    @user.respond_to?(:id).should == true
  end
  
  it "should correctly initialize a new user with defaults" do
    @user.username.should == "mocky"
    @user.display_name.should == nil
    @user.email.should == nil
    @user.access_id.length.should == 24
    @user.secret_key.length.should == 40
  end
  
  it "should correctly show acls" do
    nil
  end
  
  it "should not be activated directly after initialization" do
    @user.active?.should == false
  end
  
  it "should activate and save the user" do
    @user.activate
    @user.active?.should == true
    reloaded_user = Smoke::User.find(:username => "mocky")
    reloaded_user.active?.should == true
  end
  
  it "should have automatically created the appropriate helper methods" do
    Smoke::User.keys.keys.each do |key|
      Smoke::User.respond_to?(:"find_by_#{key}").should == true
    end
  end
  
  it "should have created the default buckets for the user on save" do
    @user.save
    @user.buckets.size.should == 2
    Smoke.database.collection('smbucket').count.should == 2
  end
  
  it "should be able to use cached buckets" do 
    @user.save
    @user.buckets(:use_cache => true).size.should == 2
    Smoke.database.collection('smbucket').count.should == 2
  end
  
  it "should not recreate buckets on subsequent saves" do
    @user.save
    @user.save
    @user.save
    @user.buckets.size.should == 2
    Smoke.database.collection('smbucket').count.should == 2
  end
  
  it "should have buckets with the correct names" do
    @user.save
    @user.bucket_names.include?("#{@user.username}").should == true
    @user.bucket_names.include?("#{@user.username}-logs").should == true
  end
  
  it "should have buckets with the correct names using has_bucket?" do
    @user.has_bucket?("#{@user.username}").should == false
    @user.save
    @user.has_bucket?("#{@user.username}").should == true
    @user.has_bucket?("#{@user.username}-logs").should == true
  end
  
  it "should authenticate with a valid password" do
    @user.password = "helloworld"
    @user.email = "mocky@dev.null.com"
    @user.save
    u = Smoke::User.authenticate(@user.username, 'helloworld')
    u.should_not == nil
    u.id.should == @user.id
    u = Smoke::User.authenticate(@user.email, 'helloworld')
    u.should_not == nil
    u.id.should == @user.id
  end
  
  it "should not authenticate with an invalid password" do
    @user.password = "helloworld"
    @user.email = "mocky@dev.null.com"
    @user.save
    u = Smoke::User.authenticate(@user.username, 'badpassword')
    u.should == nil
    u = Smoke::User.authenticate(@user.email, 'badpassword')
    u.should == nil
  end 
  
  # acl
  
  # has_permission_to?
  
  # objects
end