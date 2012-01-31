require File.dirname(__FILE__) + '/spec_helper'

describe "S3::Auth" do
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
    @user.activate
    @user.save
  end
  
  after(:each) do
    Smoke.database.collection('user').remove({})
    FileUtils.rm_r(SMOKE_CONFIG['filepath'])
  end

  def app
    # Using proc to always return a successful response as if
    # sinatra had no problems at all (we are just testing auth)
    @app ||= Smoke::S3::Auth.new(proc {|env| [200,{},[]]})
  end
  
  it "should respond to /" do
    get '/', {}, {
      "REQUEST_PATH"=>"/",
      "PATH_INFO"=>"/",
      "REQUEST_URI"=>"/",
      "HTTP_VERSION"=>"HTTP/1.0",
      "HTTP_X_REAL_IP"=>"129.101.159.162",
      "HTTP_HOST"=>"localhost",
      "HTTP_X_FORWARDED_FOR"=>"129.101.159.162",
      "HTTP_CONNECTION"=>"close",
      "HTTP_ACCEPT_ENCODING"=>"identity",
      "HTTP_AUTHORIZATION"=>"AWS 0PN5J17HBGZHT7JJ3X82:ZJTRusTkJ6luq7nJ13v89vnO7+8=",
      "HTTP_X_AMZ_DATE"=>"Thu, 08 Dec 2011 20:39:34 +0000",
      "CONTENT_LENGTH"=>"0"}
    last_response.should be_ok
  end
  
  it "should fail if signature is invalid" do
    get '/', {}, {
      "REQUEST_PATH"=>"/",
      "PATH_INFO"=>"/",
      "REQUEST_URI"=>"/",
      "HTTP_VERSION"=>"HTTP/1.0",
      "HTTP_X_REAL_IP"=>"129.101.159.162",
      "HTTP_HOST"=>"localhost",
      "HTTP_X_FORWARDED_FOR"=>"129.101.159.162",
      "HTTP_CONNECTION"=>"close",
      "HTTP_ACCEPT_ENCODING"=>"identity",
      "HTTP_AUTHORIZATION"=>"AWS 0PN5J17HBGZHT7JJ3X82:35BlhS7wZCfGggJto9qkboxnVHU=",
      "HTTP_X_AMZ_DATE"=>"Thu, 08 Dec 2011 20:39:34 +0000",
      "CONTENT_LENGTH"=>"0"}
    last_response.should_not be_ok
    Hash.from_xml_string(last_response.body)['Error']['Code'].should == "SignatureDoesNotMatch"
  end
  
  it "should fail if the user is not signed up" do
    get '/', {}, {
      "REQUEST_PATH"=>"/",
      "PATH_INFO"=>"/",
      "REQUEST_URI"=>"/",
      "HTTP_VERSION"=>"HTTP/1.0",
      "HTTP_X_REAL_IP"=>"129.101.159.162",
      "HTTP_HOST"=>"localhost",
      "HTTP_X_FORWARDED_FOR"=>"129.101.159.162",
      "HTTP_CONNECTION"=>"close",
      "HTTP_ACCEPT_ENCODING"=>"identity",
      "HTTP_AUTHORIZATION"=>"AWS 0PN5J17HBGZHT7JJ3X83:35BlhS7wZCfGggJto9qkboxnVHU=",
      "HTTP_X_AMZ_DATE"=>"Thu, 08 Dec 2011 20:39:34 +0000",
      "CONTENT_LENGTH"=>"0"}
    last_response.should_not be_ok
    Hash.from_xml_string(last_response.body)['Error']['Code'].should == "NotSignedUp"
  end
  
  it "should fail if the user is inactive" do
    @user.deactivate
    get '/', {}, {
      "REQUEST_PATH"=>"/",
      "PATH_INFO"=>"/",
      "REQUEST_URI"=>"/",
      "HTTP_VERSION"=>"HTTP/1.0",
      "HTTP_X_REAL_IP"=>"129.101.159.162",
      "HTTP_HOST"=>"localhost",
      "HTTP_X_FORWARDED_FOR"=>"129.101.159.162",
      "HTTP_CONNECTION"=>"close",
      "HTTP_ACCEPT_ENCODING"=>"identity",
      "HTTP_AUTHORIZATION"=>"AWS 0PN5J17HBGZHT7JJ3X82:ZJTRusTkJ6luq7nJ13v89vnO7+8=",
      "HTTP_X_AMZ_DATE"=>"Thu, 08 Dec 2011 20:39:34 +0000",
      "CONTENT_LENGTH"=>"0"}
    last_response.should_not be_ok
    Hash.from_xml_string(last_response.body)['Error']['Code'].should == "AccountProblem"
  end
end