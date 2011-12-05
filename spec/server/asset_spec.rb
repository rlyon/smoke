require File.dirname(__FILE__) + '/spec_helper'

describe "Asset" do
  
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

  it "should not save if the key is missing" do
    @file.key = nil
    @file.save.should be_false
  end
  
  it "should not save if the content_type is missing" do
    @file.content_type = nil
    @file.save.should be_false
  end

  it "should not save if the storage class is missing" do
    @file.storage_class = nil
    @file.save.should be_false
  end
  
  it "should not save if the size is missing" do
    @file.size = nil
    @file.save.should be_false
  end
  
  it "should have the correct path if the delete marker is not set" do
    @file.path.should == "/tmp/test/mocky/path/to/my/file.txt"
    @file.path.should_not == "/tmp/test/mocky/.trash/path/to/my/file.txt"
  end
  
  it "should have the correct path if the delete marker is set" do
    @file.delete_marker = true
    @file.path.should_not == "/tmp/test/mocky/path/to/my/file.txt"
    @file.path.should == "/tmp/test/mocky/.trash/path/to/my/file.txt"
  end
  
  it "should give the correct directory path if the delete marker is not set" do
    @file.dir.should == "/tmp/test/mocky/path/to/my/"
    @file.dir.should_not == "/tmp/test/mocky/.trash/path/to/my/"
    @dir.dir.should == "/tmp/test/mocky/path/to/my/placeholder/"
    @dir.dir.should_not == "/tmp/test/mocky/.trash/path/to/my/placeholder/"
  end
  
  it "should give the correct directory path if the delete marker is set" do
    @file.delete_marker = true
    @dir.delete_marker = true
    @file.dir.should_not == "/tmp/test/mocky/path/to/my/"
    @file.dir.should == "/tmp/test/mocky/.trash/path/to/my/"
    @dir.dir.should_not == "/tmp/test/mocky/path/to/my/placeholder/"
    @dir.dir.should == "/tmp/test/mocky/.trash/path/to/my/placeholder/"
  end
  
  it "should return the full key on pwd if it is a placeholder" do
    @dir.pwd.should == "path/to/my/placeholder/"
  end
  
  it "should return the parent directory path via pwd if it is a standard file" do
    @file.pwd.should == "path/to/my/"
  end
  
  it "should delete all acls" do
    pending "Not yet tested"
  end
  
  it "should return the filename of a file" do
    @file.filename.should == "file.txt"
  end
  
  it "should return nil if it is a placeholder" do
    @dir.filename.should be_nil
  end

  it "should return the last_prefix for files and placeholders" do
    @file.last_prefix.should == "my"
    @dir.last_prefix.should == "placeholder"
  end
  
  it "should set and release locks" do
    @file.lock
    @file.locked.should be_true
    @file.unlock
    @file.locked.should be_false
  end
  
  it "should report is_placeholder_directory? correctly" do
    @dir.is_placeholder_directory?.should be_true
  end
  
  # Append
  it "should append a line to the file" do
    pending "Not yet tested"
  end
  
  ### Write
  it "should write a file and set all the asset attributes" do
    data = File.new(File.dirname(__FILE__) + '/example/FILE1.txt', 'r')
    @bucket.is_versioning = false
    @bucket.save!
    @new_asset = @bucket.find_or_create_asset_by_key("example/FILE1.txt")
    # This is really strange, in order for the 'save' in write to work, I have to 
    # wrap it in the lock and unlock???? Why?  Probably a PEBKAC error
    @new_asset.lock
    @new_asset.write(data, 'text/plain')
    @new_asset.unlock
    data.rewind
    @new_asset.path.should == "/tmp/test/mocky/example/FILE1.txt"
    File.exists?(@new_asset.path).should be_true
    @new_asset.size.should == data.read.size
    @new_asset.content_type.should == 'text/plain'
    File.exists?("#{@new_asset.path}.upload").should be_false
  end

  it "should overwrite a file if versioning has never been enabled" do
    data = File.new(File.dirname(__FILE__) + '/example/FILE1.txt', 'r')
    @bucket.is_versioning = nil
    @bucket.save!
    @new_asset = @bucket.find_or_create_asset_by_key("example/FILE1.txt")
    @new_asset.lock
    @new_asset.write(data, 'text/plain')
    @new_asset.unlock
    
    File.open(@new_asset.path).first.should == "Hello, I am file 1.\n"
    
    data = File.new(File.dirname(__FILE__) + '/example/FILE2.txt', 'r')
    @next_asset = @bucket.find_or_create_asset_by_key("example/FILE1.txt")
    @next_asset.lock
    @next_asset.write(data, 'text/plain')
    @next_asset.unlock
    
    data.rewind
    @next_asset.id.should == @new_asset.id
    @next_asset.path.should == "/tmp/test/mocky/example/FILE1.txt"
    File.exists?(@next_asset.path).should be_true
    @next_asset.size.should == data.read.size
    @next_asset.content_type.should == 'text/plain'
    File.open(@next_asset.path).first.should == "Oh snap, I'm not 1! I'm file 2.\n"
    File.exists?("#{@next_asset.path}.upload").should be_false
  end
  
  it "should overwrite the latest file if versioning is suspended" do
    data = File.new(File.dirname(__FILE__) + '/example/FILE1.txt', 'r')
    @bucket.is_versioning = false
    @bucket.save!
    @new_asset = @bucket.find_or_create_asset_by_key("example/FILE1.txt")
    @new_asset.lock
    @new_asset.write(data, 'text/plain')
    @new_asset.unlock
    
    File.open(@new_asset.path).first.should == "Hello, I am file 1.\n"
    
    data = File.new(File.dirname(__FILE__) + '/example/FILE2.txt', 'r')
    @next_asset = @bucket.find_or_create_asset_by_key("example/FILE1.txt")
    @next_asset.lock
    @next_asset.write(data, 'text/plain')
    @next_asset.unlock
    
    data.rewind
    @next_asset.id.should == @new_asset.id
    @next_asset.path.should == "/tmp/test/mocky/example/FILE1.txt"
    File.exists?(@next_asset.path).should be_true
    @next_asset.size.should == data.read.size
    @next_asset.content_type.should == 'text/plain'
    File.open(@next_asset.path).first.should == "Oh snap, I'm not 1! I'm file 2.\n"
    File.exists?("#{@next_asset.path}.upload").should be_false
  end
  
  it "should not overwrite anything if the etag matches the digest" do
    data = File.new(File.dirname(__FILE__) + '/example/FILE1.txt', 'r')
    @bucket.is_versioning = nil
    @bucket.save!
    @new_asset = @bucket.find_or_create_asset_by_key("example/FILE1.txt")
    @new_asset.lock
    @new_asset.write(data, 'text/plain')
    @new_asset.unlock
    
    File.open(@new_asset.path).first.should == "Hello, I am file 1.\n"
    new_asset_mtime = File.new(@new_asset.path).mtime
    
    data = File.new(File.dirname(__FILE__) + '/example/FILE1.txt', 'r')
    @next_asset = @bucket.find_or_create_asset_by_key("example/FILE1.txt")
    @next_asset.lock
    @next_asset.write(data, 'text/plain')
    @next_asset.unlock
    
    data.rewind
    @next_asset.id.should == @new_asset.id
    @next_asset.path.should == "/tmp/test/mocky/example/FILE1.txt"
    File.exists?(@next_asset.path).should be_true
    @next_asset.size.should == data.read.size
    @next_asset.content_type.should == 'text/plain'
    File.open(@next_asset.path).first.should == "Hello, I am file 1.\n"
    next_asset_mtime = File.new(@next_asset.path).mtime
    next_asset_mtime.should == new_asset_mtime
    File.exists?("#{@next_asset.path}.upload").should be_false
  end
  
  it "should create a placeholder directory if the file is application/x-directory" do
    @new_asset = @bucket.find_or_create_asset_by_key("example/myfolder/")
    @new_asset.lock
    @new_asset.write("", 'application/x-directory')
    @new_asset.unlock
    
    @new_asset.is_placeholder_directory?.should be_true
    File.directory?(@new_asset.path).should be_true
  end
  
  it "should remove a parent placeholders before creating a new subfolder" do
    @new_asset = @bucket.find_or_create_asset_by_key("example/myfolder/")
    @new_asset.lock
    @new_asset.write("", 'application/x-directory')
    @new_asset.unlock
    @new_asset.is_placeholder_directory?.should be_true
    File.directory?(@new_asset.path).should be_true
    
    old_path = @new_asset.path
    
    @new_asset = @bucket.find_or_create_asset_by_key("example/myfolder/mysubfolder/")
    @new_asset.lock
    @new_asset.write("", 'application/x-directory')
    @new_asset.unlock
    @new_asset.is_placeholder_directory?.should be_true
    File.directory?(@new_asset.path).should be_true
    File.directory?(old_path).should be_true
    @bucket.assets.find_by_key("example/myfolder/").should be_nil
  end
  
  it "should create a new version and store the file before creating the new file" do
    data = File.new(File.dirname(__FILE__) + '/example/FILE1.txt', 'r')
    @bucket.is_versioning = true
    @bucket.save!
    @new_asset = @bucket.find_or_create_asset_by_key("example/FILE1.txt")
    @new_asset.lock
    @new_asset.write(data, 'text/plain')
    @new_asset.unlock
    
    data = File.new(File.dirname(__FILE__) + '/example/FILE2.txt', 'r')
    @next_asset = @bucket.find_or_create_asset_by_key("example/FILE1.txt")
    @next_asset.lock
    @next_asset.write(data, 'text/plain')
    @next_asset.unlock
    
    @next_asset.versions.count.should == 1
    @version = @next_asset.versions.find(:all).first
    
    data.rewind
    File.open(@next_asset.path).first.should == "Oh snap, I'm not 1! I'm file 2.\n"
    File.open(@version.path).first.should == "Hello, I am file 1.\n"
    File.exists?("#{@next_asset.path}.upload").should be_false
  end
  
  it "should create a placeholder if the last file is marked for deletion" do
    pending "Not yet tested"
  end
  
  it "should move all files to the trash if a file is marked for deletion" do
    data = File.new(File.dirname(__FILE__) + '/example/FILE1.txt', 'r')
    @bucket.is_versioning = true
    @bucket.save!
    @new_asset = @bucket.find_or_create_asset_by_key("example/FILE1.txt")
    @new_asset.lock
    @new_asset.write(data, 'text/plain')
    @new_asset.unlock
    
    data = File.new(File.dirname(__FILE__) + '/example/FILE2.txt', 'r')
    @next_asset = @bucket.find_or_create_asset_by_key("example/FILE1.txt")
    @next_asset.lock
    @next_asset.write(data, 'text/plain')
    @next_asset.unlock
    
    @next_asset.mark_for_delete
    @next_asset.path.should == "/tmp/test/mocky/.trash/example/FILE1.txt"
    # Interesting, this kept on erroring here (well furthur on down). As
    # the asset that version was reading was a cached version when I used
    # @next_asset.versions.first.  The following statement seems to clear 
    # the cache.  I don't know how much of a performance hit it will be.
    @version = @next_asset.versions.find(:all).first
    # pp @version.path
    # pp @next_asset
    # pp @version.asset
    # pp @next_asset.dir
    # @version.path.should == "/tmp/test/mocky/.trash/example/FILE1.txt.xxxxx"

    File.open(@next_asset.path).first.should == "Oh snap, I'm not 1! I'm file 2.\n"
    File.open(@version.path).first.should == "Hello, I am file 1.\n"
  end
  
  it "should adjust the delete marker if the asset to be written to has the delete marker set" do
    data = File.new(File.dirname(__FILE__) + '/example/FILE1.txt', 'r')
    @bucket.is_versioning = false
    @bucket.save!
    @new_asset = @bucket.find_or_create_asset_by_key("example/FILE1.txt")
    @new_asset.lock
    @new_asset.write(data, 'text/plain')
    @new_asset.unlock
    
    @new_asset.mark_for_delete
    
    data = File.new(File.dirname(__FILE__) + '/example/FILE1.txt', 'r')
    @new_asset = @bucket.find_or_create_asset_by_key("example/FILE1.txt")
    @new_asset.lock
    @new_asset.write(data, 'text/plain')
    @new_asset.unlock
    
    @new_asset.delete_marker.should be_false
  end
  
  it "should return an array of permissions" do
    @file.permissions(@user).should be_a(Array)
  end
  
  it "should all the owner to do anything" do
    @file.permissions(@user).should == [:full_control,:read,:write,:read_acl,:write_acl]
  end
  
  it "should contain the 'global' permissions assigned to the bucket" do
    pending "Not yet tested"
  end
  
  it "should give the correct basename" do
    @file.basename.should be_nil
    @file.basename('/','path/to/').should be_nil
    @file.basename('/','path/to/my/').should == "file.txt"
    @dir.basename.should be_nil
  end
  
  it "should give the correct dirname" do
    @file.dirname.should == "path/"
    @file.dirname('/', 'path/').should == "to/"
    @file.dirname('/', 'path/to/').should == "my/"
    @file.dirname('/', 'path/to/my/').should be_nil
    @dir.dirname('/', 'path/to/my/').should == "placeholder/"
  end
  
end