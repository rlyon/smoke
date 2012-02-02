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
    @asset.allow(@bocky, :read)
    @asset.save
    
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
    h.has_key?('ListBucketResult').should be_true
    h['ListBucketResult']['Name'].should == "mocky"
    h['ListBucketResult']['Prefix'].should == nil
    h['ListBucketResult']['Marker'].should == nil
    h['ListBucketResult']['IsTruncated'].should == "false"
    h['ListBucketResult'].has_key?('Contents').should be_true
    c = h['ListBucketResult']['Contents']
    # length doesn't work here as there is only on value and c should be a hash
    c.should be_a(Array)
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
    @object.store(data)
    
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
  
  it "should create a bucket" do
    @user.max_buckets = 3
    @user.save
    put  '/testbucket/', '', {'smoke.user' => @user}
    last_response.should be_ok
    testbucket = Smoke::SmBucket.find_by_name('testbucket')
    testbucket.should_not be_nil
    @user.buckets.include?(testbucket).should be_true
  end
  
  it "should not allow the creation of more than the max buckets" do
    put  '/testbucket/', '', {'smoke.user' => @user}
    last_response.should_not be_ok
    Hash.from_xml_string(last_response.body)['Error']['Code'].should == "TooManyBuckets"
    testbucket = Smoke::SmBucket.find_by_name('testbucket')
    testbucket.should be_nil
  end
  
  it "should save a file" do
    file = 'testfiles/bacon.txt'
    etag = 'd4c228bdc5749ea3b20c3e07d5f1eb65'
    data = File.new(File.dirname(__FILE__) + '/' + file, 'r')
    put '/mocky/bacon.txt', data.read, {'smoke.user' => @user}
    last_response.should be_ok
    @newfile = Smoke::SmObject.find_by_object_key('bacon.txt')
    File.exists?(@newfile.path).should be_true
    File.exists?("#{@newfile.path}.upload").should be_false
    @newfile.path.should == @newfile.active_path
  end
  
  it "shouldn't save a file to a bucket not owned by the user (without permission)" do
    file = 'testfiles/bacon.txt'
    etag = 'd4c228bdc5749ea3b20c3e07d5f1eb65'
    data = File.new(File.dirname(__FILE__) + '/' + file, 'r')
    put '/mocky/bacon.txt', data.read, {'smoke.user' => @bocky}
    last_response.should_not be_ok
    Hash.from_xml_string(last_response.body)['Error']['Code'].should == "AccessDenied"
  end
  
  it "should save a file if the requestor has write privileges" do
    bucket = Smoke::SmBucket.find_by_name('mocky')
    bucket.allow(@bocky, "write")
    
    file = 'testfiles/bacon.txt'
    etag = 'd4c228bdc5749ea3b20c3e07d5f1eb65'
    data = File.new(File.dirname(__FILE__) + '/' + file, 'r')
    put '/mocky/bacon.txt', data.read, {'smoke.user' => @bocky}
    last_response.should be_ok
    @newfile = Smoke::SmObject.find_by_object_key('bacon.txt')
    File.exists?(@newfile.path).should be_true
    File.exists?("#{@newfile.path}.upload").should be_false
    @newfile.path.should == @newfile.active_path
  end
  
  it "should overwrite a file" do
    file = 'testfiles/bacon.txt'
    etag = 'd4c228bdc5749ea3b20c3e07d5f1eb65'
    data = File.new(File.dirname(__FILE__) + '/' + file, 'r')
    put '/mocky/file.txt', data.read, {'smoke.user' => @user}
    last_response.should be_ok
    @newfile = Smoke::SmObject.find_by_object_key('file.txt')
    File.exists?(@newfile.path).should be_true
    File.exists?("#{@newfile.path}.upload").should be_false
    @newfile.etag.should == etag
    @newfile.path.should == @newfile.active_path
    
    file = 'testfiles/lorem.txt'
    etag = '8c1d67521736f5cfaf5367982eba302f'
    data = File.new(File.dirname(__FILE__) + '/' + file, 'r')
    put '/mocky/file.txt', data.read, {'smoke.user' => @user}
    last_response.should be_ok
    @newfile = Smoke::SmObject.find_by_object_key('file.txt')
    File.exists?(@newfile.path).should be_true
    File.exists?("#{@newfile.path}.upload").should be_false
    @newfile.etag.should == etag
    @newfile.path.should == @newfile.active_path
  end
  
  it "should just delete the file that was uploaded if etags match" do
    file = 'testfiles/bacon.txt'
    etag = 'd4c228bdc5749ea3b20c3e07d5f1eb65'
    data = File.new(File.dirname(__FILE__) + '/' + file, 'r')
    put '/mocky/file.txt', data.read, {'smoke.user' => @user}
    last_response.should be_ok
    @newfile = Smoke::SmObject.find_by_object_key('file.txt')
    File.exists?(@newfile.path).should be_true
    File.exists?("#{@newfile.path}.upload").should be_false
    @newfile.etag.should == etag
    @newfile.path.should == @newfile.active_path
    
    file = 'testfiles/bacon.txt'
    etag = 'd4c228bdc5749ea3b20c3e07d5f1eb65'
    data = File.new(File.dirname(__FILE__) + '/' + file, 'r')
    put '/mocky/file.txt', data.read, {'smoke.user' => @user}
    last_response.should be_ok
    @newfile = Smoke::SmObject.find_by_object_key('file.txt')
    File.exists?(@newfile.path).should be_true
    File.exists?("#{@newfile.path}.upload").should be_false
    @newfile.etag.should == etag
    @newfile.path.should == @newfile.active_path
  end
  
  it "should respond to get bucket logging" do
    get '/mocky/', {'logging' => nil}, {'smoke.user' => @user}
    last_response.should be_ok
  end
  
  it "should disable bucket logging" do
    @bucket.logging = true
    @bucket.save
    
    # sanity check
    bucket = Smoke::SmBucket.find_by_name('mocky')
    bucket.logging?.should be_true
    xml = '<?xml version="1.0" encoding="UTF-8"?><BucketLoggingStatus xmlns="http://doc.s3.amazonaws.com/2006-03-01" />'
    put '/mocky/?logging', xml, {'smoke.user' => @user}
    last_response.should be_ok
    bucket = Smoke::SmBucket.find_by_name('mocky')
    bucket.logging?.should be_false
  end
  
  it "should enable bucket logging" do
    # sanity check
    bucket = Smoke::SmBucket.find_by_name('mocky')
    bucket.logging?.should be_false
    xml = '<?xml version="1.0" encoding="UTF-8"?><BucketLoggingStatus xmlns="http://doc.s3.amazonaws.com/2006-03-01"><LoggingEnabled></LoggingEnabled></BucketLoggingStatus>'
    put '/mocky/?logging', xml, {'smoke.user' => @user}
    last_response.should be_ok
    bucket = Smoke::SmBucket.find_by_name('mocky')
    bucket.logging?.should be_true
  end
  
  it "should respond to put bucket notification" do
    put '/mocky/', {'notification' => nil}, {'smoke.user' => @user}
    last_response.should_not be_ok
    Hash.from_xml_string(last_response.body)['Error']['Code'].should == "NotImplemented"
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