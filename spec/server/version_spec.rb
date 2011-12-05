require File.dirname(__FILE__) + '/spec_helper'

describe "Version" do
  
  before(:each) do
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
    @bucket ||= @user.buckets.find(1)
    @file ||= @bucket.assets.new(:key => "path/to/my/file.txt", :size => 100)
    @file.save!
    @version = @file.versions.new(:version_string => "myrandomstring")
    @version.save!
  end
  
  after(:each) do
    ActiveRecord::Base.connection.rollback_db_transaction
    ActiveRecord::Base.connection.decrement_open_transactions
  end

  it "should return path as a string" do
    @version.path.should be_a(String)
  end
  
  it "should have the name .file.txt.myrandomstring" do
    @version.name.should == ".file.txt.myrandomstring"
  end

  it "should have a full path of /tmp/test/mocky/path/to/my/.file.txt.myrandomstring" do
    @version.path.should == "/tmp/test/mocky/path/to/my/.file.txt.myrandomstring"
  end

end