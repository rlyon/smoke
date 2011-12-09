require File.dirname(__FILE__) + '/spec_helper'

describe "Acl" do
  
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
  end
  
  it "should parse valid xml content when using a cannonical user" do
    xml = '<AccessControlPolicy>
    <Owner>
    <ID>0PN5J17HBGZHT7JJ3X82</ID>
    <DisplayName>mocky@dev.null.com</DisplayName>
    </Owner>
    <AccessControlList>
    <Grant>
    <Grantee xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance"
    xsi:type="CanonicalUser">
    <ID>0PN5J17HBGZHT7JJ3X83</ID>
    <DisplayName>bocky@dev.null.com</DisplayName>
    </Grantee>
    <Permission>READ</Permission>
    </Grant>
    </AccessControlList>
    </AccessControlPolicy>'
    Smoke::Server::Acl.from_xml(xml, @bucket) do |acl|
      acl.save!
    end
    acls = Smoke::Server::Acl.find(:all)
    acls.length.should == 1
    acl = acls.first
    acl.user_id.should == @bocky.id
    acl.bucket_id.should == @bucket.id
  end
  
  it "should parse valid xml content when using a an email address to identify the grantee" do
    xml = '<AccessControlPolicy>
    <Owner>
    <ID>0PN5J17HBGZHT7JJ3X82</ID>
    <DisplayName>mocky@dev.null.com</DisplayName>
    </Owner>
    <AccessControlList>
    <Grant>
    <Grantee xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance"
    xsi:type="AmazonCustomerByEmail">
    <EmailAddress>bocky@dev.null.com</EmailAddress>
    </Grantee>
    <Permission>READ</Permission>
    </Grant>
    </AccessControlList>
    </AccessControlPolicy>'
    Smoke::Server::Acl.from_xml(xml, @bucket) do |acl|
      acl.save!
    end
    acls = Smoke::Server::Acl.find(:all)
    acls.length.should == 1
    acl = acls.first
    acl.user_id.should == @bocky.id
    acl.bucket_id.should == @bucket.id
  end
end