require File.dirname(__FILE__) + '/spec_helper'

describe "User" do
  
  before(:each) do
    FileUtils.mkdir(SMOKE_CONFIG['filepath'])
    ActiveRecord::Base.connection.increment_open_transactions
    ActiveRecord::Base.connection.begin_db_transaction
    @user = Smoke::Server::User.new(  
      :access_id => "0PN5J17HBGZHT7JJ3X82", 
      :expires_at => Time.now.to_i + (60*60*24*28), 
      :secret_key => "uV3F3YluFJax1cknvbcGwgjvx4QpvB+leU8dUj2o",
      :username => "mocky",
      :password => "mysecretpassword",
      :display_name => "Mocky User",
      :email => "mocky@dev.null.com",
      :role => "admin")
    @user.save!
    
    @bocky = Smoke::Server::User.new(
      :access_id => "0PN5J17HBGZHT7JJ3X83", 
      :expires_at => Time.now.to_i + (60*60*24*28), 
      :secret_key => "uV3F3YluFJax1cknvbcGwgjvx4QpvB+leU8dUj2p",
      :username => "bocky",
      :password => "mysecretpassword",
      :display_name => "Bocky User",
      :email => "bocky@dev.null.com"
    )
    @bocky.save!
    
    @bucket ||= @user.buckets.find_by_name(@user.username)
    @file ||= @bucket.assets.new(:key => "path/to/my/file.txt", :size => 100, :user_id => @user.id)
    @file.save!
    @dir ||= @bucket.assets.new(:key => "path/to/my/placeholder/", :size => 100, :content_type => 'application/x-directory', :user_id => @user.id)
    @dir.save!
  end
  
  after(:each) do
    ActiveRecord::Base.connection.rollback_db_transaction
    ActiveRecord::Base.connection.decrement_open_transactions
    FileUtils.rm_r(SMOKE_CONFIG['filepath'])
  end

  it "all_my_buckets should return all buckets including shared" do
    @bucket.create_acl!(@bocky, "read")
    @bocky.all_my_buckets.length.should == 3
    @user.all_my_buckets.length.should == 2
  end
  
  it "should return the correct permissions with for a user with access" do
    @bucket.create_acl!(@bocky, "read")
    @bocky.has_permission_to(:read, @bucket).should be_true
  end
  
  it "should authenticate with valid email and password" do
    Smoke::Server::User.authenticate("mocky@dev.null.com", "mysecretpassword").should == @user
  end
  
  it "should authenticate with valid username and password" do
    Smoke::Server::User.authenticate("mocky", "mysecretpassword").should == @user
  end
  
  it "should report a valid status if active" do
    @user.is_active = true
    @user.has_valid_status?.should be_true
  end
  
  it "should report a invalid status if inactive" do
    @user.is_active = false
    @user.has_valid_status?.should be_false
  end

end 