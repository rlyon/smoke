require File.dirname(__FILE__) + '/spec_helper'

describe "Signature" do
  it "should do sign a service request" do
    s = Smoke::Signature.new("uV3F3YluFJax1cknvbcGwgjvx4QpvB+leU8dUj2o",
      :method => "GET", 
      :path => "/", 
      :date => "Tue, 27 Mar 2007 19:36:42 +0000"
    )
    s.sign.should == "35BlhS7wZCfGggJto9qkboxnVHU="
  end
  
  it "should sign a get request" do
    s = Smoke::Signature.new("uV3F3YluFJax1cknvbcGwgjvx4QpvB+leU8dUj2o",
      :method => "GET", 
      :path => "/photos/puppy.jpg", 
      :bucket => "johnsmith", 
      :date => "Tue, 27 Mar 2007 19:36:42 +0000"
    )
    s.sign.should == "xXjDGYUmKxnwqr5KXNPGldn5LbA="
  end
  
  it "should sign a get request with expires" do
    s = Smoke::Signature.new("uV3F3YluFJax1cknvbcGwgjvx4QpvB+leU8dUj2o",
      :method => "GET", 
      :path => "/photos/puppy.jpg", 
      :bucket => "johnsmith", 
      :expires => "Tue, 27 Mar 2007 19:36:42 +0000"
    )
    s.sign.should == "xXjDGYUmKxnwqr5KXNPGldn5LbA="
  end
  
  it "should sign a list request" do
    s = Smoke::Signature.new("uV3F3YluFJax1cknvbcGwgjvx4QpvB+leU8dUj2o",
      :method => "GET", 
      :path => "/",
      :params => {'prefix' => 'photos', 'max-keys' => '50', 'marker' => 'puppy'},
      :bucket => "johnsmith", 
      :date => "Tue, 27 Mar 2007 19:42:41 +0000"
    )
    s.sign.should == "jsRt/rhG+Vtp88HrYL706QhE4w4="
  end
  
  it "should sign an acl fetch" do
    s = Smoke::Signature.new("uV3F3YluFJax1cknvbcGwgjvx4QpvB+leU8dUj2o",
      :method => "GET",
      :path => "/",
      :params => { 'acl' => nil }, 
      :bucket => "johnsmith", 
      :date => "Tue, 27 Mar 2007 19:44:46 +0000"
    )
    s.sign.should == "thdUi9VAkzhkniLj96JIrOPGi0g="
  end
  
  it "shouldn't sign an invalid request" do
    s = Smoke::Signature.new("uV3F3YluFJax1cknvbcGwgjvx4QpvB+leU8dUj2o",
      :method => "GET", 
      :path => "/photos/puppy.jpg", 
      :bucket => "johnsmith", 
      :date => "Tue, 27 Mar 2007 19:36:42 +0000"
    )
    s.sign.should_not == "thdUi9VAkzhkniLj96JIrOPGi0g="
  end
  
  it "should sign a put request" do
    s = Smoke::Signature.new("uV3F3YluFJax1cknvbcGwgjvx4QpvB+leU8dUj2o",
      :method => "PUT", 
      :path => "/photos/puppy.jpg",
      :type => "image/jpeg",
      :bucket => "johnsmith", 
      :date => "Tue, 27 Mar 2007 21:15:45 +0000"
    )
    s.sign.should == "hcicpDDvL9SsO6AkvxqmIWkmOuQ="
  end
  
  it "should sign a delete request with amz date" do
    s = Smoke::Signature.new("uV3F3YluFJax1cknvbcGwgjvx4QpvB+leU8dUj2o",
      :method => "DELETE", 
      :path => "/photos/puppy.jpg",
      :bucket => "johnsmith",
      :amz_headers => { 'x-amz-date' => ["Tue, 27 Mar 2007 21:20:26 +0000"]}
    )
    s.sign.should == "k3nL7gH3+PadhTEVn5Ip83xlYzk="
  end
  
  it "should sign an upload request" do
    s = Smoke::Signature.new("uV3F3YluFJax1cknvbcGwgjvx4QpvB+leU8dUj2o",
      :method => "PUT", 
      :path => "/db-backup.dat.gz",
      :type => "application/x-download",
      :md5 => "4gJE4saaMU4BqNR0kLY+lw==",
      :date => "Tue, 27 Mar 2007 21:06:08 +0000",
      :bucket => "static.johnsmith.net",
      :amz_headers => { "x-amz-acl" => ["public-read"],
                        "x-amz-meta-reviewedby" => ["joe@johnsmith.net", "jane@johnsmith.net"],
                        "x-amz-meta-filechecksum" => ["0x02661779"],
                        "x-amz-meta-checksumalgorithm" => ["crc32"]}
    )
    s.sign.should == "C0FlOtU8Ylb9KDTpZqYkZPX91iI="
  end
end