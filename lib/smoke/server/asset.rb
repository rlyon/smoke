require 'fileutils'

module Smoke
  module Server
    class Asset < ActiveRecord::Base
      belongs_to :user
      belongs_to :bucket
      has_many :acls, :dependent => :destroy
      has_many :versions, :dependent => :destroy
      
      # should validate the format of the key to only allow [A-Za-z0-9]+ to 
      # start and / as the only delimiter for now
      validates :key, :presence => true
      validates :key, :uniqueness => { :scope => :bucket_id }
      validates :size, :presence => true
      validates :storage_class, :presence => true
      validates :content_type, :presence => true
      
      # before_save :convert_path_to_key
      before_destroy :unlink_file
      
      scope :not_marked_for_deletion, where(:delete_marker => false)
      scope :marked_for_deletion, where(:delete_marker => true)
      # scope :without_placeholder_directory, find(:all, :conditions => "content_type != 'application/x-directory'")
      # scope :placeholder_directories, where(:content_type => "application/x-directory")
      
      def path
        unless self.delete_marker?
          active_path
        else
          trash_path
        end
      end
      
      def active_path
        "#{SMOKE_CONFIG['filepath']}/#{self.bucket.name}/#{self.key}"
      end
      
      def trash_path
        "#{SMOKE_CONFIG['filepath']}/#{self.bucket.name}/.trash/#{self.key}"
      end
      
      def dir
        unless self.delete_marker?
          active_dir
        else
          trash_dir
        end
      end
      
      def active_dir
        "#{SMOKE_CONFIG['filepath']}/#{self.bucket.name}/#{pwd}"
      end
      
      def trash_dir
        "#{SMOKE_CONFIG['filepath']}/#{self.bucket.name}/.trash/#{pwd}"
      end
      
      def pwd
        unless is_placeholder_directory?
          self.key.split('/')[0..-2].join('/') + '/'
        else
          self.key
        end
      end
      
      def filename
        unless is_placeholder_directory?
          self.key.split('/').last
        else
          nil
        end
      end
      
      def last_prefix
        unless is_placeholder_directory?
          self.key.split('/')[0..-2].last
        else
          self.key.split('/').last
        end
      end
      
      def remove_acls
        self.acls.delete_all
      end
      
      def lock
        self.locked = true
        save
      end
      
      def unlock
        self.locked = false
        save
      end
      
      def is_placeholder_directory?
        self.content_type == "application/x-directory"
      end
      
      def permissions(user)
        return [:full_control,:read,:write,:read_acl,:write_acl] if self.user.id == user.id
        # return [:full_control,:read,:write,:read_acl,:write_acl] if self.bucket.user.id == user.id
        
        a = self.acls.where(:user_id => user.id)
        a << self.bucket.acls.where(:user_id => user.id)
        a.map {|acl| acl.permission.to_sym}
      end
      
      #
      # Return the next prefix from start.  For example, 
      # myasset.dirname('/', 'path/to') would return nil for an asset
      # with the key 'path/to/image.jpg' and 'my/' for an asset with the
      # key 'path/to/my/image.jpg'.
      # 
      def dirname(delimiter = '/', start = nil)
        prefix = self.key
        unless start.nil?
          prefix = prefix.gsub(start,'')
        end
        
        arr = prefix.split(delimiter)
        if arr.length > 1
          arr[0] + delimiter
        elsif arr.length == 1 && is_placeholder_directory?
          arr[0] + delimiter
        else
          nil
        end
      end
      
      #
      # Not really basename in the unix sense, but returns the basenames for the 
      # assets that are found at the start prefix.  For example, 
      # myasset.basename('/', 'path/to') would return 'image.jpg' for an asset
      # with the key 'path/to/image.jpg' and nil for an asset with the
      # key 'path/to/my/image.jpg'.
      #
      def basename(delimiter = '/', start = nil)
        return nil if is_placeholder_directory? 
        
        prefix = self.key
        unless start.nil?
          prefix = prefix.gsub(start,'')
        end
        
        arr = prefix.split(delimiter)
        if arr.length == 1
          arr[0]
        else
          nil
        end
      end
      
      def mark_for_delete
        create_parent_placeholder_if_last
        self.delete_marker = true
        self.delete_at = 30.days
        save
        trash_files
      end
      
      def marked_for_delete?
        self.delete_marker?
      end
      
      def append(data)
        # Ensure that the directory exists
        FileUtils.mkpath dir

        File.open(path, 'a') do |file|
          file.write(data)
        end
        digest = Digest::MD5.hexdigest(File.read(tempfile)).to_s
        self.etag = digest 
        self.size = File.size(path)
        save
      end
        
      def write(data, type)
        self.content_type = type
        remove_parent_placeholers
        
        if marked_for_delete?
          self.delete_marker = false
          self.delete_at = nil
        end
        
        unless self.is_placeholder_directory?
          # Ensure that the directory exists
          FileUtils.mkpath dir
          tempfile = "#{path}.upload"
          File.open(tempfile, 'wb') do |file|
            file.write(data.read)
          end
          digest = Digest::MD5.hexdigest(File.read(tempfile)).to_s
        
          # Don't bother anything if the digest hasn't changed.  Should check
          # prior to writing the file.
          unless self.etag == digest
            # If the file exists, I'm assuming the asset attributes are current...
            if File.exist?(path) && self.bucket.is_versioning?
              # Create a new version.
              @version = self.versions.new(
                :version_string => "#{String.random :length => 32}", 
                :etag => self.etag,
                :size => self.size,
                :content_type => self.content_type
              )
              @version.save
              # Move the current version before we copy the temp file back.  Really should
              # have a background process to compress the files to save space.
              FileUtils.move path, @version.path
            end
            # There's got to be a better way to do this...  I need to rewind so I can get the size
            # Otherwise it gives me the remaining bytes, which is 0.
            data.rewind
            self.etag = digest
            self.size = data.read.size
            FileUtils.move tempfile, path, :force => true
          else
            FileUtils.rm tempfile
          end
        else
          FileUtils.mkpath dir
          self.size = 0
        end 
        save!
      end

    private
      # Makes sure that the key is in ascii format and does not
      # have the leading forward slash.
      def convert_path_to_key
        self.key = URI.decode(self.key)
        self.key = self.key[1..-1] if self.key[0] == '/'
      end
      
      # Removes the physical file associated with the asset 
      def unlink_file
        unless is_placeholder_directory?
          FileUtils.rm path if File.file?(path)
        else
          FileUtils.rmdir path if Dir.entries(path) == [".", ".."]
        end
      end
      
      def restore_file
        nil
      end
      
      def trash_files
        FileUtils.mkpath trash_dir
        unless is_placeholder_directory?
          FileUtils.mv active_path, trash_dir, :force => true if File.file?(active_path)
        else
          FileUtils.rmdir active_path
          FileUtils.mkdir trash_path
        end
        
        self.versions.each do |version|
          version.move_to_trash
        end
      end
      
      def create_parent_placeholder_if_last
        parent_directory = self.pwd
        asset_list = Asset.find( :all, 
          :conditions => [  "bucket_id = ? AND key LIKE ? AND delete_marker = ?", 
                            self.bucket.id, 
                            "#{parent_directory}%", 
                            false]
        )
        
        if asset_list.length == 1 # Its just me left
          asset = Asset.new(:user_id => self.user_id, :bucket_id => self.bucket_id, :key => parent_directory)
          asset.write("", "application/x-directory")
        end
      end
      
      # Probably not the best way to go about this.  There will be too many
      # calls to the database.  Just a quick and dirty attempt.
      def remove_parent_placeholers
        self.key.split('/')[0..-2].inject("") do |x,y|
          x << y + '/'
          asset = Asset.find_by_key(x)
          unless asset.nil?
            asset.destroy if asset.is_placeholder_directory?
          end
          x
        end
      end
      
    end
  end
end