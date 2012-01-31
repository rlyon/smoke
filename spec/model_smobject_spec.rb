require File.dirname(__FILE__) + '/spec_helper'

describe "Smoke::SmBucket" do
  
  before(:each) do
    @bucket = Smoke::SmBucket.new(:name => "bucket")
    @obj1 = Smoke::SmObject.new(:object_key => 'path/to/my/super/cool/file.txt', :bucket_id => @bucket.id)
    @bucket.save
    @obj1.save
  end
  
  after(:each) do
    Smoke.database.collection('smbucket').remove({})
    Smoke.database.collection('smobject').remove({})
    FileUtils.rm_r(SMOKE_CONFIG['filepath']) if File.exists?(SMOKE_CONFIG['filepath'])
  end
  
  it "should give the correct basename" do
    @obj1.basename.should == "file.txt"
  end
  
  it "should give the correct dirname" do
    @obj1.dirname.should == "path/to/my/super/cool/"
  end
  
  it "should lock" do
    @obj1.lock
    @obj1.locked?.should == true
  end
  
  it "should unlock" do
    @obj1.unlock
    @obj1.locked?.should == false
  end
  
  it "should have a valid active path" do
    @obj1.active_path.should == "/tmp/test/bucket/path/to/my/super/cool/file.txt"
  end
  
  it "should have a valid trash path" do
    @obj1.trash_path.should == "/tmp/test/bucket/.trash/path/to/my/super/cool/file.txt"
  end
  
  it "should store an object" do
    file = 'testfiles/bacon.txt'
    etag = 'd4c228bdc5749ea3b20c3e07d5f1eb65'
    data = File.new(File.dirname(__FILE__) + '/' + file, 'r')
    @obj1.store(data,etag)
    @obj1.etag.should == etag
    @obj1.size.should == 19971
    File.exists?(@obj1.path).should be_true
    File.exists?("#{@obj1.path}.upload").should be_false
    @obj1.path.should == @obj1.active_path
  end
  
  it "should send a file to the trash" do
    file = 'testfiles/bacon.txt'
    etag = 'd4c228bdc5749ea3b20c3e07d5f1eb65'
    data = File.new(File.dirname(__FILE__) + '/' + file, 'r')
    @obj1.store(data,etag)
    @obj1.etag.should == etag
    @obj1.size.should == 19971
    
    @obj1.trash
    File.exists?(@obj1.active_path).should be_false
    File.exists?(@obj1.trash_path).should be_true
    @obj1.path.should == @obj1.trash_path
  end
  
  it "should copy a file" do
    file = 'testfiles/bacon.txt'
    etag = 'd4c228bdc5749ea3b20c3e07d5f1eb65'
    data = File.new(File.dirname(__FILE__) + '/' + file, 'r')
    @obj1.store(data,etag)
    @obj1.etag.should == etag
    @obj1.size.should == 19971
    
    copy = @obj1.copy :to => 'path/to/my/super/cool/other.txt'
    copy.etag.should == etag
    copy.size.should == 19971
    
    File.exists?(@obj1.active_path).should be_true
    File.exists?(copy.active_path).should be_true
  end
end
