require File.dirname(__FILE__) + '/spec_helper'

describe "Smoke::SmBucket" do
  
  before(:each) do
    @bucket = Smoke::SmBucket.new(:name => "bucket")
    @obj1 = Smoke::SmObject.new(:bucket_id => @bucket.id, :key => 'path/to/my/super/cool/file.txt')
    @obj2 = Smoke::SmObject.new(:bucket_id => @bucket.id, :key => 'path/to/my/super/cool/other.txt')
    @obj3 = Smoke::SmObject.new(:bucket_id => @bucket.id, :key => 'path/to/my/super/cool/mine.txt')
    @obj4 = Smoke::SmObject.new(:bucket_id => @bucket.id, :key => 'path/to/this/file.txt')
    @obj5 = Smoke::SmObject.new(:bucket_id => @bucket.id, :key => 'path/to/this/other.txt')
    @obj6 = Smoke::SmObject.new(:bucket_id => @bucket.id, :key => 'path/to/this/mine.txt')
    @obj7 = Smoke::SmObject.new(:bucket_id => @bucket.id, :key => 'path/to/file.txt')
    @obj8 = Smoke::SmObject.new(:bucket_id => @bucket.id, :key => 'path/to/other.txt')
    @obj9 = Smoke::SmObject.new(:bucket_id => @bucket.id, :key => 'path/to/mine.txt')
    @obj10 = Smoke::SmObject.new(:bucket_id => @bucket.id, :key => 'path/to/placeholder/', :is_placeholder => true)
    @bucket.save
    @obj1.save
    @obj2.save
    @obj3.save
    @obj4.save
    @obj5.save
    @obj6.save
    @obj7.save
    @obj8.save
    @obj9.save
    @obj10.save
  end
  
  after(:each) do
    Smoke.database.collection('smbucket').remove({})
    Smoke.database.collection('smobject').remove({})
  end
  
  it "should have the correct defaults set" do
    @bucket.name.should == "bucket"
    @bucket.user_id.should == nil
    @bucket.is_logging.should == false
    @bucket.is_versioning.should == false
    @bucket.is_notifying.should == false
    @bucket.storage.should == "local"
    @bucket.location.should == "unset"
    @bucket.visibility.should == "private"
  end
  
  it "should return the correct common prefixes" do
    cp = @bucket.common_prefixes
    cp.size.should == 1
    cp.include?('path/').should == true
    
    cp = @bucket.common_prefixes('path/to/')
    cp.size.should == 3
    cp.include?('path/to/this/').should == true
    cp.include?('path/to/my/').should == true
    cp.include?('path/to/placeholder/').should == true
  end
  
  it "should return the keys in the provided path" do
    keys = @bucket.objects(:prefix => 'path/to/my/super/cool/', :recursive => false)
    keys.size.should == 3
    keys.include?(@obj1).should == true
    keys.include?(@obj2).should == true
    keys.include?(@obj3).should == true
    
    keys = @bucket.objects(:prefix => 'path/to/this/', :recursive => false)
    keys.size.should == 3
    keys.include?(@obj4).should == true
    keys.include?(@obj5).should == true
    keys.include?(@obj6).should == true
    
    keys = @bucket.objects(:prefix => 'path/to/', :recursive => false)
    keys.size.should == 3
    keys.include?(@obj7).should == true
    keys.include?(@obj8).should == true
    keys.include?(@obj9).should == true
  end
  
  it "should report that it has objects" do
    @bucket.has_objects?.should == true
  end
  
  it "should return all of it's objects" do
    objects = @bucket.objects
    objects.size.should == 10
    objects.include?(@obj1).should == true
    objects.include?(@obj2).should == true
    objects.include?(@obj3).should == true
    objects.include?(@obj4).should == true
    objects.include?(@obj5).should == true
    objects.include?(@obj6).should == true
    objects.include?(@obj7).should == true
    objects.include?(@obj8).should == true
    objects.include?(@obj9).should == true
    objects.include?(@obj10).should == true
  end
  
  it "should return all of it's objects if prefix is nil" do
    objects = @bucket.objects :prefix => nil
    objects.size.should == 10
    objects.include?(@obj1).should == true
    objects.include?(@obj2).should == true
    objects.include?(@obj3).should == true
    objects.include?(@obj4).should == true
    objects.include?(@obj5).should == true
    objects.include?(@obj6).should == true
    objects.include?(@obj7).should == true
    objects.include?(@obj8).should == true
    objects.include?(@obj9).should == true
    objects.include?(@obj10).should == true
  end
  
  it "should return all of it's objects through cache" do
    objects = @bucket.objects(:use_cache => true)
    objects.size.should == 10
    objects.include?(@obj1).should == true
    objects.include?(@obj2).should == true
    objects.include?(@obj3).should == true
    objects.include?(@obj4).should == true
    objects.include?(@obj5).should == true
    objects.include?(@obj6).should == true
    objects.include?(@obj7).should == true
    objects.include?(@obj8).should == true
    objects.include?(@obj9).should == true
    objects.include?(@obj10).should == true
  end
  
  # logging from xml
  
  # notification from xml
  
  # versioning through xml
  
end