require File.dirname(__FILE__) + '/spec_helper'

describe "S3::App" do
  include Rack::Test::Methods
  
  before(:each) do
    FileUtils.mkdir(SMOKE_CONFIG['filepath'])
    
    @user = Smoke::User.new(  
      :access_id => "0PN5J17HBGZHT7JJ3X82", 
      :expires_at => Time.now.to_i + (60*60*24*28), 
      :secret_key => "uV3F3YluFJax1cknvbcGwgjvx4QpvB+leU8dUj2o",
      :username => "mocky",
      :password => "mysecretpassword",
      :display_name => "Mocky User",
      :email => "mocky@dev.null.com",
      :role => "admin")
    @user.save
    @creep = Smoke::User.new(  
      :access_id => "0PN5J17HBGZHT7JJ3X83", 
      :expires_at => Time.now.to_i + (60*60*24*28), 
      :secret_key => "uV3F3YluFJax1cknvbcGwgjvx4QpvB+leU8dUj2o",
      :username => "creep",
      :password => "mysecretpassword",
      :display_name => "Creepy Hacker",
      :email => "creep@dev.null.com"
      )
    @creep.save
    @bocky = Smoke::User.new(
      :access_id => "0PN5J17HBGZHT7JJ3X84", 
      :expires_at => Time.now.to_i + (60*60*24*28), 
      :secret_key => "uV3F3YluFJax1cknvbcGwgjvx4QpvB+leU8dUj2p",
      :username => "bocky",
      :password => "mysecretpassword",
      :display_name => "Bocky User",
      :email => "bocky@dev.null.com"
    )
    @bocky.save
    
    @bucket = @user.buckets.first
    
    @obj = Smoke::SmObject.new(:object_key => 'path/to/my/file.txt', :user_id => @user.id, :bucket_id => @bucket.id, :size => 100)
    @obj.save
    @obj = Smoke::SmObject.new(:object_key => 'README', :user_id => @user.id, :bucket_id => @bucket.id, :size => 100)
    @obj.save
    @obj = Smoke::SmObject.new(:object_key => 'example/file.txt', :user_id => @user.id, :bucket_id => @bucket.id, :size => 100)
    @obj.save
    @dir = Smoke::SmObject.new(:object_key => 'path/to/my/placeholder/', :user_id => @user.id, :bucket_id => @bucket.id, :size => 100)
    @dir.save
    
  end
  
  after(:each) do
    Smoke.database.collection('user').remove({})
    Smoke.database.collection('smbucket').remove({})
    Smoke.database.collection('smobject').remove({})
    
    FileUtils.rm_r(SMOKE_CONFIG['filepath']) if File.exists?(SMOKE_CONFIG['filepath'])
  end

  def app
    @app ||= Smoke::S3::App.new
  end
  
  #
  # Since we are only testing the app itself, I'm assuming that the 
  # rack authentication has already set everything it needs (hence the
  # rack request parameters being set in the request)
  #
  
  it "should respond to /" do
    get '/', {}, {'smoke.user' => @user}
    last_response.should be_ok
    h = Hash.from_xml_string(last_response.body)
    h.has_key?('ListAllMyBucketResult').should be_true
    r = h['ListAllMyBucketResult']
    r.has_key?('Buckets').should be_true
    r['Buckets']['Bucket'].length.should == 2
  end
  
  it "should respond to / and list all buckets including shared" do
    @bucket.allow(@bocky, "read")
    
    get '/', {}, {'smoke.user' => @bocky}
    last_response.should be_ok
    h = Hash.from_xml_string(last_response.body)
    h.has_key?('ListAllMyBucketResult').should be_true
    r = h['ListAllMyBucketResult']
    r.has_key?('Buckets').should be_true
    r['Buckets']['Bucket'].length.should == 3
    
    get '/', {}, {'smoke.user' => @user}
    last_response.should be_ok
    h = Hash.from_xml_string(last_response.body)
    h.has_key?('ListAllMyBucketResult').should be_true
    r = h['ListAllMyBucketResult']
    r.has_key?('Buckets').should be_true
    r['Buckets']['Bucket'].length.should == 2
  end
  
  it "should respond to / and list all buckets including those with shared assets" do
    @asset = Smoke::SmObject.find_by_object_key('path/to/my/file.txt')
    @asset.allow(@bocky, "read")
    
    get '/', {}, {'smoke.user' => @bocky}
    last_response.should be_ok
    h = Hash.from_xml_string(last_response.body)
    h.has_key?('ListAllMyBucketResult').should be_true
    r = h['ListAllMyBucketResult']
    r.has_key?('Buckets').should be_true
    r['Buckets']['Bucket'].length.should == 3
    
    get '/', {}, {'smoke.user' => @user}
    last_response.should be_ok
    h = Hash.from_xml_string(last_response.body)
    h.has_key?('ListAllMyBucketResult').should be_true
    r = h['ListAllMyBucketResult']
    r.has_key?('Buckets').should be_true
    r['Buckets']['Bucket'].length.should == 2
  end
  
  it "should not list the same bucket more than once if multiple assets are shared" do
    @asset = Smoke::SmObject.find_by_object_key('path/to/my/file.txt')
    @asset.allow(@bocky, "read")
    @asset = Smoke::SmObject.find_by_object_key('example/file.txt')
    @asset.allow(@bocky, "read")
    
    get '/', {}, {'smoke.user' => @bocky}
    last_response.should be_ok
    h = Hash.from_xml_string(last_response.body)
    h.has_key?('ListAllMyBucketResult').should be_true
    r = h['ListAllMyBucketResult']
    r.has_key?('Buckets').should be_true
    r['Buckets']['Bucket'].length.should == 3
  end
  
  it "should list all the files when no delimeter is present" do
    get '/mocky/', {}, {'smoke.user' => @user}
    last_response.should be_ok
    h = Hash.from_xml_string(last_response.body)
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
    h = Hash.from_xml_string(last_response.body)
    puts h.inspect
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
    @object = Smoke::SmObject.find(:bucket_id => @bucket.id, :object_key => 'path/to/my/file.txt')
    file = 'testfiles/bacon.txt'
    etag = 'd4c228bdc5749ea3b20c3e07d5f1eb65'
    data = File.new(File.dirname(__FILE__) + '/' + file, 'r')
    @object.store(data,etag)
    
    delete '/mocky/path/to/my/file.txt', {}, {'smoke.user' => @user}
    last_response.should be_ok
    @object = Smoke::SmObject.find(:bucket_id => @bucket.id, :object_key => 'path/to/my/file.txt')
    @object.deleted?.should be_true
  end
  
  it "shouldn't mark a bucket asset for delete if it exists and user does not have permissison" do
    delete '/mocky/path/to/my/file.txt', {}, {'smoke.user' => @creep}
    last_response.should_not be_ok
    Hash.from_xml_string(last_response.body)['Error']['Code'].should == "AccessDenied"
    @object = Smoke::SmObject.find(:bucket_id => @bucket.id, :object_key => 'path/to/my/file.txt')
    @object.deleted?.should be_false
  end
  
  it "get asset shouldn't be able to find an invalid key" do
    get '/mocky/anyfile', {}, {'smoke.user' => @user}
    last_response.should_not be_ok
    Hash.from_xml_string(last_response.body)['Error']['Code'].should == "NoSuchKey"
  end
  
  it "get asset should respond to invalid parameter" do
    get '/mocky/README', {'mymadeupparam' => nil}, {'smoke.user' => @user}
    last_response.should_not be_ok
    Hash.from_xml_string(last_response.body)['Error']['Code'].should == "InvalidArgument"
  end
  
  ### Check some of the stubs
  it "get bucket should respond to paramater requestPayment" do
    get '/mocky/', {'requestPayment' => nil}, {'smoke.user' => @user}
    last_response.should_not be_ok
    Hash.from_xml_string(last_response.body)['Error']['Code'].should == "NotImplemented"
  end
  
  it "get bucket should respond to paramater website" do
    get '/mocky/', {'website' => nil}, {'smoke.user' => @user}
    last_response.should_not be_ok
    Hash.from_xml_string(last_response.body)['Error']['Code'].should == "NotImplemented"
  end
  
  it "get bucket should respond to paramater location" do
    get '/mocky/', {'location' => nil}, {'smoke.user' => @user}
    last_response.should_not be_ok
    Hash.from_xml_string(last_response.body)['Error']['Code'].should == "NotImplemented"
  end
  
  it "get bucket should respond to paramater notification" do
    get '/mocky/', {'notification' => nil}, {'smoke.user' => @user}
    last_response.should_not be_ok
    Hash.from_xml_string(last_response.body)['Error']['Code'].should == "NotImplemented"
  end
  
  it "get asset should respond to paramater torrent" do
    get '/mocky/README', {'torrent' => nil}, {'smoke.user' => @user}
    last_response.should_not be_ok
    Hash.from_xml_string(last_response.body)['Error']['Code'].should == "NotImplemented"
  end

end