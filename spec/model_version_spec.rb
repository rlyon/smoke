require File.dirname(__FILE__) + '/spec_helper'

describe "Smoke::Version" do
  
  before(:each) do
    @bucket = Smoke::SmBucket.new(:name => "bucket")
    @obj1 = Smoke::SmObject.new(:object_key => 'path/to/my/super/cool/file.txt', :bucket_id => @bucket.id)
    @ver1 = Smoke::Version.new(:object_id => @obj1.id)
    @bucket.save
    @obj1.save
    @ver1.save
  end
  
  after(:each) do
    Smoke.database.collection('smbucket').remove({})
    Smoke.database.collection('smobject').remove({})
    FileUtils.rm_r(SMOKE_CONFIG['filepath']) if File.exists?(SMOKE_CONFIG['filepath'])
  end
  
  it "should return the object that is versioned" do
    @ver1.object.should == @obj1
  end
  
  it "should return the correct path" do
    @ver1.path.should == "#{@obj1.dirname}/.#{@obj1.basename}.#{@ver1.version_string}"
  end
  
end