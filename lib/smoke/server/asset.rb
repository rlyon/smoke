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
      validates :key, :uniqueness => true
      validates :size, :presence => true
      validates :storage_class, :presence => true
      
      before_save :convert_path_to_key
      before_destroy :unlink_file
      
      def filename
        self.key.split('/').last
      end
      
      def lock
        self.locked = true
        self.save
      end
      
      def is_placeholder_directory?
        self.content_type == "application/x-directory"
      end
      
      def remove_placeholders
        self.key.split('/')[0..-1].inject("") do |x,y|
          x << y + '/'
          puts "CLEANING: #{x}"
          asset = Asset.find_by_key(x)
          unless asset.nil?
            puts "DESTROYING PLACEHOLDER"
            asset.destroy if asset.is_placeholder_directory?
          end
          x
        end
      end
      
      def unlock
        self.locked = false
        save
      end
      
      def append(data)
        full_path = "#{SMOKE_CONFIG['filepath']}/#{self.bucket.name}/#{self.key}"
        dir = full_path.split('/')[0..-2].join('/')
        # Ensure that the directory exists
        FileUtils.mkpath dir

        File.open(full_path, 'a') do |file|
          file.write(data)
        end
        digest = Digest::MD5.hexdigest(File.read(tempfile)).to_s
        self.etag = digest 
        self.size = File.size(full_path)
        save
      end
        
      def write(data, type)
        full_path = "#{SMOKE_CONFIG['filepath']}/#{self.bucket.name}/#{self.key}"
        dir = full_path.split('/')[0..-2].join('/')
        filename = full_path.split('/').last
        
        self.content_type = type
        self.remove_placeholders
        
        unless self.is_placeholder_directory?
          # Ensure that the directory exists
          FileUtils.mkpath dir
          tempfile = "#{dir}/#{filename}.upload"
          File.open(tempfile, 'wb') do |file|
            file.write(data.read)
          end
          digest = Digest::MD5.hexdigest(File.read(tempfile)).to_s
        
          # Don't bother anything if the digest hasn't changed.  Should check
          # prior to writing the file.
          unless self.etag == digest
            # If the file exists, I'm assuming the asset attributes are current...
            if File.exist?(full_path) && self.bucket.is_versioning?
              # Create a new version.
              @version = self.versions.new(
                :version_string => "#{String.random :length => 32}", 
                :etag => self.etag,
                :size => self.size,
                :content_type => self.content_type
              )
              @version.save
              version_path = "#{dir}/.#{filename}.#{@version.version_string}"
              # Move the current version before we copy the temp file back.  Really should
              # have a background process to compress the files to save space.
              FileUtils.move full_path, version_path
            end
            # There's got to be a better way to do this...  I need to rewind so I can get the size
            # Otherwise it gives me the remaining bytes, which is 0.
            data.rewind
            self.etag = digest 
            self.path = full_path 
            self.size = data.read.size
            FileUtils.move tempfile, full_path, :force => true
          else
            FileUtils.rm tempfile
          end
        else
          FileUtils.mkpath full_path
          self.path = full_path 
          self.size = 0
        end 
        save
      end
      
      def mark_for_delete
        self.delete_marker = true
        self.delete_at = Time.now.to_i + (60*60*24*30)
      end
      
      def permissions(user)
        return [:full_control,:read,:write,:read_acl,:write_acl] if self.user.id == user.id
        return [:full_control,:read,:write,:read_acl,:write_acl] if self.bucket.user.id == user.id
        
        a = self.acls.where(:user_id == user.id)
        a << self.bucket.acls.where(:user_id == user.id)
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
          FileUtils.rm self.path if File.file?(self.path)
        else
          FileUtils.rmdir self.path if Dir.entries(self.path) == [".", ".."]
        end
      end
      
      def restore_file
        nil
      end
      
      def trash_file
        puts self.inspect
        trash_path = "#{SMOKE_CONFIG['filepath']}/#{self.bucket.name}/.trash/#{self.key}"
        dir = trash_path.split('/')[0..-2].join('/')
        FileUtils.mkpath dir
        unless is_placeholder_directory?
          FileUtils.mv self.path, dir, :force => true if File.file?(self.path)
        else
          FileUtils.rmdir self.path
          FileUtils.mkdir trash_path
        end
      end
      
    end
  end
end