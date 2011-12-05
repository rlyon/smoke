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

  def app
    @app ||= Smoke::Server::App.new
  end

  it "should respond to /" do
    get '/', {}, {'smoke.user' => @user}
    last_response.should be_ok
  end

end