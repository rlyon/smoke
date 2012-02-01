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
  end
    
  after(:each) do
    Smoke.database.collection('user').remove({})
    FileUtils.rm_r(SMOKE_CONFIG['filepath']) if File.exists?(SMOKE_CONFIG['filepath'])
  end
  
  def app
    @app ||= Smoke::S3::App.new
  end

  it "should respond to /" do
    get '/', {}, {'smoke.user' => @user}
    last_response.should be_ok
    h = Hash.from_xml_string(last_response.body)
    h.has_key?('ListAllMyBucketResult').should be_true
    r = h['ListAllMyBucketResult']
    r.has_key?('Buckets').should be_true
    r['Buckets']['Bucket'].length.should == 2
  end
  
  ###
  ### Stubs
  ###
  it "should respond to / with users as a param" do
    get '/', {'users' => nil}, {'smoke.user' => @user}
    last_response.should_not be_ok
    Hash.from_xml_string(last_response.body)['Error']['Code'].should == "NotImplemented"
  end

  it "should respond to / with user as a param" do
    get '/', {'user' => nil}, {'smoke.user' => @user}
    last_response.should_not be_ok
    Hash.from_xml_string(last_response.body)['Error']['Code'].should == "NotImplemented"
  end

end
    