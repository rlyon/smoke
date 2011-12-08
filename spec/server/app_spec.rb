require File.dirname(__FILE__) + '/spec_helper'

describe "App" do
  include Rack::Test::Methods
  
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
    @creep = Smoke::Server::User.new(  
      :access_id => "0PN5J17HBGZHT7JJ3X83", 
      :expires_at => Time.now.to_i + (60*60*24*28), 
      :secret_key => "uV3F3YluFJax1cknvbcGwgjvx4QpvB+leU8dUj2o",
      :username => "creep",
      :password => "mysecretpassword",
      :display_name => "Creepy Hacker",
      :email => "creep@dev.null.com"
      )
    @creep.save!
    
    @bucket ||= @user.buckets.find_by_name(@user.username)
    @file = @bucket.assets.new(:key => "path/to/my/file.txt", :size => 100, :user_id => @user.id)
    @file.save!
    @file = @bucket.assets.new(:key => "README", :size => 100, :user_id => @user.id)
    @file.save!
    @file = @bucket.assets.new(:key => "example/file.txt", :size => 100, :user_id => @user.id)
    @file.save!
    @dir = @bucket.assets.new(:key => "path/to/my/placeholder/", :size => 100, :content_type => 'application/x-directory', :user_id => @user.id)
    @dir.save!
    
    
  end
  
  after(:each) do
    ActiveRecord::Base.connection.rollback_db_transaction
    ActiveRecord::Base.connection.decrement_open_transactions
    FileUtils.rm_r(SMOKE_CONFIG['filepath'])
  end

  def app
    @app ||= Smoke::Server::App.new
  end
  
  #
  # Since we are only testing the app itself, I'm assuming that the 
  # rack authentication has already set everything it needs (hence the
  # rack request parameters being set in the request)
  #
  
  it "should respond to /" do
    get '/', {}, {'smoke.user' => @user}
    last_response.should be_ok
    h = Hash.from_xml(last_response.body)
    h.has_key?('ListAllMyBucketResult').should be_true
    r = h['ListAllMyBucketResult']
    r.has_key?('Buckets').should be_true
    r['Buckets']['Bucket'].length.should == 2
  end
  
  it "should list all the files when no delimeter is present" do
    get '/mocky/', {}, {'smoke.user' => @user}
    last_response.should be_ok
    h = Hash.from_xml(last_response.body)
    h.has_key?('ListBucketResult').should be_true
    h['ListBucketResult']['Name'].should == "mocky"
    h['ListBucketResult']['Prefix'].should == nil
    h['ListBucketResult']['Marker'].should == nil
    h['ListBucketResult']['IsTruncated'].should == "false"
    h['ListBucketResult'].has_key?('Contents').should be_true
    c = h['ListBucketResult']['Contents']
    c.length.should == 4
  end
  
  it "should only list the files at the prefix with a list of common prefixes when the delimiter is present" do
    get '/mocky/', {'delimiter' => '/'}, {'smoke.user' => @user}
    last_response.should be_ok
    h = Hash.from_xml(last_response.body)
    h.has_key?('ListBucketResult').should be_true
    h['ListBucketResult']['Name'].should == "mocky"
    h['ListBucketResult']['Prefix'].should == nil
    h['ListBucketResult']['Marker'].should == nil
    h['ListBucketResult']['IsTruncated'].should == "false"
    h['ListBucketResult'].has_key?('Contents').should be_true
    c = h['ListBucketResult']['Contents']
    # length doesn't work here as there is only on value and c should be a hash
    c.should be_a(Hash)
    h['ListBucketResult'].has_key?('CommonPrefixes').should be_true
    cp =h['ListBucketResult']['CommonPrefixes']
    cp.length.should == 2
    cp.first['Prefix'].should == 'path/'
    cp.last['Prefix'].should == 'example/'
  end
  
  it "should mark a bucket asset for delete if it exists and user has permissison" do
    delete '/mocky/path/to/my/file.txt', {}, {'smoke.user' => @user}
    last_response.should be_ok
    @bucket.assets.find_by_key('path/to/my/file.txt').marked_for_delete?.should be_true
  end
  
  it "shouldn't mark a bucket asset for delete if it exists and user does not have permissison" do
    delete '/mocky/path/to/my/file.txt', {}, {'smoke.user' => @creep}
    last_response.should_not be_ok
    Hash.from_xml(last_response.body)['Error']['Code'].should == "AccessDenied"
    @bucket.assets.find_by_key('path/to/my/file.txt').marked_for_delete?.should be_false
  end
  
  it "get asset shouldn't be able to find an invalid key" do
    get '/mocky/anyfile', {}, {'smoke.user' => @user}
    last_response.should_not be_ok
    Hash.from_xml(last_response.body)['Error']['Code'].should == "NoSuchKey"
  end
  
  it "get asset should respond to invalid parameter" do
    get '/mocky/README', {'mymadeupparam' => nil}, {'smoke.user' => @user}
    last_response.should_not be_ok
    Hash.from_xml(last_response.body)['Error']['Code'].should == "InvalidArgument"
  end
  
  ### Check some of the stubs
  it "get bucket should respond to paramater requestPayment" do
    get '/mocky/', {'requestPayment' => nil}, {'smoke.user' => @user}
    last_response.should_not be_ok
    Hash.from_xml(last_response.body)['Error']['Code'].should == "NotImplemented"
  end
  
  it "get bucket should respond to paramater website" do
    get '/mocky/', {'website' => nil}, {'smoke.user' => @user}
    last_response.should_not be_ok
    Hash.from_xml(last_response.body)['Error']['Code'].should == "NotImplemented"
  end
  
  it "get bucket should respond to paramater location" do
    get '/mocky/', {'location' => nil}, {'smoke.user' => @user}
    last_response.should_not be_ok
    Hash.from_xml(last_response.body)['Error']['Code'].should == "NotImplemented"
  end
  
  it "get bucket should respond to paramater notification" do
    get '/mocky/', {'notification' => nil}, {'smoke.user' => @user}
    last_response.should_not be_ok
    Hash.from_xml(last_response.body)['Error']['Code'].should == "NotImplemented"
  end
  
  it "get asset should respond to paramater torrent" do
    get '/mocky/README', {'torrent' => nil}, {'smoke.user' => @user}
    last_response.should_not be_ok
    Hash.from_xml(last_response.body)['Error']['Code'].should == "NotImplemented"
  end

end