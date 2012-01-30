module Smoke
  module Plugins
    module LocalFileStore
      
      def self.included(klass)
        klass.key :object_key, String
        klass.key :size, Integer, :default => 0
        klass.key :storage_class, String, :default => "standard"
        klass.key :etag, String
        klass.key :content_type, String, :default => "application/octet-stream"
        klass.key :locked, Boolean, :default => false
        klass.key :delete_marker, Boolean, :default => false
        klass.key :deleted_at, Time, :default => Time.now
        klass.key :is_placeholder, Boolean, :default => false
      end
     
      def active_dir
        "#{SMOKE_CONFIG['filepath']}/#{self.bucket.name}/#{self.dirname}"
      end
      
      def active_path
        "#{SMOKE_CONFIG['filepath']}/#{self.bucket.name}/#{self.object_key}"
      end
            
      def basename(args = {})
        args.include_only(:delimiter)
        delimiter = args.has_key?(:delimiter) ? args[:delimiter] : '/'
        self.object_key.split(delimiter).last
      end
      
      def deleted?
        self.delete_marker == true
      end
            
      def delete_object(path)
        FileUtils.rm path
      end
      
      def delete_folder(path)
        nil
      end
      
      def dirname(args = {})
        args.include_only(:delimiter)
        delimiter = args.has_key?(:delimiter) ? args[:delimiter] : '/'
        self.object_key.split(delimiter)[0..-2].join(delimiter) + delimiter
      end
      
      def lock
        self.locked = true
        self.save
      end
            
      def move_object(args = {})
        args.include_only(:source, :destination, :force)
        raise "[LocalFileStore.move_object]: Source must be specified" unless args.has_key?(:source)
        raise "[LocalFileStore.move_object]: Destination must be specified" unless args.has_key?(:destination)
        force = args.has_key?(:force) ? args[:force] : false
        FileUtils.move args[:source], args[:destination], :force => force
      end
         
      def mkdir(path)
        FileUtils.mkpath path
      end
      
      def path
        if self.deleted?
          trash_path
        else
          active_path
        end
      end

      def store_object(args = {}, &block)
        args.include_only(:data, :etag, :versioning)
        raise "[LocalFileStore.store_object]: Data required but not specified." unless args.has_key?(:data)
        raise "[LocalFileStore.store_object]: ETag required but not specified." unless args.has_key?(:etag)
        
        etag = args[:etag]
        versioning = args.has_key?(:versioning) ? args[:versioning] : false
        
        self.mkdir(self.active_dir)
        tempfile = "#{active_path}.upload"
        
        File.open(tempfile, 'wb') do |file|
          file.write(args[:data].read)
        end
        
        digest = Digest::MD5.hexdigest(File.read(tempfile)).to_s
      
        # Don't bother anything if the digest hasn't changed.  Should check
        # prior to writing the file.
        if etag == digest
          # If the file exists, I'm assuming the asset attributes are current...
          if File.exist?(active_path) && versioning
            # Create a new version.
            #@version = self.versions.new(
            #  :version_string => "#{String.random :length => 32}", 
            #  :etag => self.etag,
            #  :size => self.size,
            #  :content_type => self.content_type
            #)
            #@version.save
            # Move the current version before we copy the temp file back.  Really should
            # have a background process to compress the files to save space.
            FileUtils.move path, @version.path
          end
          # There's got to be a better way to do this...  I need to rewind so I can get the size
          # Otherwise it gives me the remaining bytes, which is 0.
          args[:data].rewind
          self.size = args[:data].read.size
          self.move_object :source => tempfile, :destination => active_path, :force => true
        else
          self.delete_object tempfile
          raise "[LocalFileStore.store_object]: Digests do not match"
        end
        yield digest,size if block_given?
      end
  
      def trash_dir
        "#{SMOKE_CONFIG['filepath']}/#{self.bucket.name}/.trash/#{self.dirname}"
      end
      
      def trash_object(path)
        self.delete_marker = true
        self.mkdir(self.trash_dir)
        self.move_object :source => self.active_path, :destination => self.trash_path, :force => true
        self.save
      end
      
      def trash_path
        "#{SMOKE_CONFIG['filepath']}/#{self.bucket.name}/.trash/#{self.object_key}"
      end
  
      def unlock
        self.locked = false
        self.save
      end
      
      def version_object(path, version)
        nil
      end
        
    end    
  end
end