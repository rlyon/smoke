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
        klass.key :deleted_at, Time, :default => nil
        klass.key :is_placeholder, Boolean, :default => false
        klass.key :is_version, Boolean, :default => false
        klass.key :version_string, String, :default => String.random(:length => 32)
        klass.key :versioned_at, Time, :default => Time.now
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
      
      def copy(args = {})
        args.include_only(:to)
        raise "[LocalFileStore.move]: Destination must be specified" unless args.has_key?(:to)
        new_file = self.mimic(:except => [:is_version, :version_string, :object_key, :locked, :delete_marker])
        new_file.object_key = args[:to]
        new_file.save
        FileUtils.cp self.active_path, new_file.active_path
        new_file
      end
      
      def deleted?
        self.delete_marker == true
      end
            
      def delete(path)
        FileUtils.rm path
      end
      
      def rmfolder(path)
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
            
      def move(args = {})
        args.include_only(:source, :destination, :force)
        raise "[LocalFileStore.move]: Source must be specified" unless args.has_key?(:source)
        raise "[LocalFileStore.move]: Destination must be specified" unless args.has_key?(:destination)
        force = args.has_key?(:force) ? args[:force] : false
        FileUtils.move args[:source], args[:destination], :force => force
      end
         
      def mkdir(path)
        FileUtils.mkpath path
      end
      
      def path
        if self.deleted?
          trash_path
        elsif self.is_version?
          version_path
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
        unless self.etag == digest
          # If the file exists, I'm assuming the asset attributes are current...
          if File.exist?(active_path) && versioning
            unless self.mkversion
              raise "[LocalFileStore.store_object]: Unable to create version."
            end
          end
          # There's got to be a better way to do this...  I need to rewind so I can get the size
          # Otherwise it gives me the remaining bytes, which is 0.
          args[:data].rewind
          self.size = args[:data].read.size
          self.move :source => tempfile, :destination => active_path, :force => true
        else
          self.delete tempfile
        end
        yield digest,size if block_given?
      end
  
      def trash_dir
        "#{SMOKE_CONFIG['filepath']}/#{self.bucket.name}/.trash/#{self.dirname}"
      end
      
      def trash_object
        self.delete_marker = true
        self.mkdir(self.trash_dir)
        self.move :source => self.active_path, :destination => self.trash_path, :force => true
        self.save
      end
      
      def trash_path
        "#{SMOKE_CONFIG['filepath']}/#{self.bucket.name}/.trash/#{self.object_key}"
      end
  
      def unlock
        self.locked = false
        self.save
      end
      
      def mkversion
        new_file = self.mimic(:except => [:is_version, :version_string, :versioned_at, :locked, :delete_marker])
        new_file.is_version = true
        new_file.versioned_at = Time.now
        
        FileUtils.cp self.active_path, new_file.version_path
        unless new_file.save
          nil
        else
          new_file
        end
      end
      
      def versions
        @objects = SmObject.where(:object_key => self.object_key, :is_version => true)
      end
      
      def version_path
        "#{self.active_dir}/.#{self.basename}.#{self.version_string}"
      end
        
    end    
  end
end