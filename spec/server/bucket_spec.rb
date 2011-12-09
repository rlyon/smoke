require File.dirname(__FILE__) + '/spec_helper'

describe "Bucket" do
  
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
      :access_id => "0PN5J17HBGZHT7JJ3X84", 
      :expires_at => Time.now.to_i + (60*60*24*28), 
      :secret_key => "uV3F3YluFJax1cknvbcGwgjvx4QpvB+leU8dUj2p",
      :username => "bocky",
      :password => "mysecretpassword",
      :display_name => "Bocky User",
      :email => "bocky@dev.null.com"
    )
    @bocky.save!
    @bucket ||= @user.buckets.find_by_name(@user.username)
    @log_bucket ||= @user.buckets.find_by_name("#{@user.username}-logs")
    @file ||= @bucket.assets.new(:key => "path/to/my/file.txt", :size => 100, :user_id => @user.id)
    @file.save!
    @dir ||= @bucket.assets.new(:key => "path/to/my/placeholder/", :size => 100, :content_type => 'application/x-directory', :user_id => @user.id)
    @dir.save!
    @log ||= @log_bucket.assets.new(:key => "path/to/my/file.txt", :size => 100, :user_id => @user.id)
    @log.save!
  end
  
  after(:each) do
    ActiveRecord::Base.connection.rollback_db_transaction
    ActiveRecord::Base.connection.decrement_open_transactions
    FileUtils.rm_r(SMOKE_CONFIG['filepath'])
  end
  
  it "should contain the correct number of files" do
    @bucket.assets.count.should == 2
    @log_bucket.assets.count.should == 1
  end
  
  it "should not be logging by default" do
    @bucket.is_logging.should be_false
  end
  
  it "should not be versioning by default" do
    @bucket.is_versioning.should be_false
  end
  
  it "should not be notifying by default" do
    @bucket.is_notifying.should be_false
  end
  
  it "should return an existing asset with find_or_create_asset_by_key" do
    @asset = @bucket.find_or_create_asset_by_key("path/to/my/file.txt")
    @asset.should == @file
  end
  
  it "should return a new asset when there is no existing asset" do
    @asset = @bucket.find_or_create_asset_by_key("path/to/my/file.txts")
    @asset.should_not == @file
  end
  
  it "should take acls and assign them to the bucket" do
    @acls = []
    @acl = Smoke::Server::Acl.new(:user_id => @bocky.id, :bucket_id => @bucket.id, :permission => "read")
    @acl.save
    @acls << @acl
    @bucket.assign_acls(@acls)
    @bucket.acls.length.should == 1
  end
  
  it "should give read permissions on the bucket to someone with access to assets in the bucket" do
    @asset = Smoke::Server::Asset.find_by_key('path/to/my/file.txt')
    @acl = Smoke::Server::Acl.new(:user_id => @bocky.id, :asset_id => @asset.id, :permission => "read")
    @acl.save

    @bocky.has_permission_to(:read, @bucket).should be_true
  end
  
  it "should remove acls for a given user" do
    @acls = []
    @acl = Smoke::Server::Acl.new(:user_id => @bocky.id, :bucket_id => @bucket.id, :permission => "read")
    @acl.save
    @acls << @acl
    @bucket.assign_acls(@acls)
    @bocky.has_permission_to(:read, @bucket).should be_true
    @bucket.remove_acls_by_user_id(@bocky.id)
    @bocky.has_permission_to(:read, @bucket).should be_false
  end
  
end