require 'fileutils'

module Smoke
  class SmObject
    include Smoke::Document
    include Smoke::Plugins::Permissions
    include Smoke::Plugins::LocalFileStore
    
    key :user_id, String
    key :bucket_id, String
    
    def bucket
      # how do we cache and still update after the move?
      @bucket ||= SmBucket.find(:_id => self.bucket_id)
    end
    
    def delete
      trash_object(self.active_path)
    end
      

    def store(data, etag)
      store_object(:data => data, :etag => etag ) do |digest,size|
        self.size = size
        self.etag = digest
      end  
    end
    
    # belongs_to :user
    # belongs_to :bucket
    # has_many :acls, :dependent => :destroy
    # has_many :versions, :dependent => :destroy
#     
    # # should validate the format of the key to only allow [A-Za-z0-9]+ to 
    # # start and / as the only delimiter for now
    # validates :key, :presence => true
    # validates :key, :uniqueness => { :scope => :bucket_id }
    # validates :size, :presence => true
    # validates :storage_class, :presence => true
    # validates :content_type, :presence => true
#     
    # # before_save :convert_path_to_key
    # before_destroy :unlink_file
#     

  # private
    # # Makes sure that the key is in ascii format and does not
    # # have the leading forward slash.
    # def convert_path_to_key
      # self.key = URI.decode(self.key)
      # self.key = self.key[1..-1] if self.key[0] == '/'
    # end
#     
    # # Removes the physical file associated with the asset 
    # def unlink_file
      # unless is_placeholder_directory?
        # FileUtils.rm path if File.file?(path)
      # else
        # FileUtils.rmdir path if Dir.entries(path) == [".", ".."]
      # end
    # end
#     
    # def restore_file
      # nil
    # end
#     
    # def trash_files
      # FileUtils.mkpath trash_dir
      # unless is_placeholder_directory?
        # FileUtils.mv active_path, trash_dir, :force => true if File.file?(active_path)
      # else
        # FileUtils.rmdir active_path
        # FileUtils.mkdir trash_path
      # end
#       
      # self.versions.each do |version|
        # version.move_to_trash
      # end
    # end
#     
    # def create_parent_placeholder_if_last
      # parent_directory = self.pwd
      # asset_list = Asset.find( :all, 
        # :conditions => [  "bucket_id = ? AND key LIKE ? AND delete_marker = ?", 
                          # self.bucket.id, 
                          # "#{parent_directory}%", 
                          # false]
      # )
#       
      # if asset_list.length == 1 # Its just me left
        # asset = Asset.new(:user_id => self.user_id, :bucket_id => self.bucket_id, :key => parent_directory)
        # asset.write("", "application/x-directory")
      # end
    # end
#     
    # # Probably not the best way to go about this.  There will be too many
    # # calls to the database.  Just a quick and dirty attempt.
    # def remove_parent_placeholers
      # self.key.split('/')[0..-2].inject("") do |x,y|
        # x << y + '/'
        # asset = Asset.find_by_key(x)
        # unless asset.nil?
          # asset.destroy if asset.is_placeholder_directory?
        # end
        # x
      # end
    # end
#     
  # end
  end
end