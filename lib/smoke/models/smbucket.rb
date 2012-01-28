module Smoke
  # From the amazon s3 developers guide the following restrictions are placed on bucket names:
  # To comply with Amazon S3 requirements, bucket names:
  #     Can contain lowercase letters, numbers, periods (.), underscores (_), and dashes (-)
  #     Must start with a number or letter
  #     Must be between 3 and 255 characters long 
  #     Must not be formatted as an IP address (e.g., 192.168.5.4)
  #
  # To conform with DNS requirements, we recommend following these additional guidelines when creating buckets:
  #     Bucket names should not contain underscores (_)
  #     Bucket names should be between 3 and 63 characters long
  #     Bucket names should not end with a dash
  #     Bucket names cannot contain two, adjacent periods
  #     Bucket names cannot contain dashes next to periods (e.g., "my-.bucket.com" and "my.-bucket" are invalid)
  #
  class SmBucket
    include Smoke::Document
    include Smoke::Plugins::Permissions
    
    attr_reader :truncated
    
    key :name, String
    key :user_id, String
    key :is_logging, Boolean, :default => false
    key :is_versioning, Boolean, :default => false
    key :is_notifying, Boolean, :default => false
    key :storage, String, :default => "local"
    key :location, String, :default => "unset"
    key :visibility, String, :default => "private"
    
    def common_prefixes(prefix)
      prefixes = []
      rx = Regexp.new('^' + prefix + '[a-zA-Z0-9_\.\-]*\/')
      objects.where(:refresh => true, :prefix => rx).each do |object|
        p = rx.match(object.prefix).to_s
        prefixes << p unless p.empty || prefixes.include?(p)
      end
      prefixes
    end
    
    def objects_in(prefix)
      objs = []
      rx = Regexp.new('^' + prefix + '[a-zA-Z0-9\.\-\_]+$')
      objects.where(:refresh => true, :prefix => rx).each do |object|
        p = rx.match(object.prefix).to_s
        objs << p unless p.empty || objs.include?(p)
      end
    end
    
    def has_objects?
      self.objects.empty? == false
    end
    
    def logging_from_xml(xml)
      l = Hash.from_xml(xml)
      raise S3Exception.new(:InvalidRequest, 'Logging tags not found.') unless v.has_key?('BucketLoggingStatus')
      if l.has_key?('LoggingEnabled')
        self.is_logging = true
      else
        self.is_logging = false
      end
      save
    end
    
    def objects(args = {})
      args.include_only(:refresh, :query, :sort)
      
      # Update the query with the bucket id
      query = args.has_key?(:query) ? args[:query] : {}
      query[:bucket_id] = self.id
      
      # Set the sorting direction... put this back in connector ???
      sort = [["key", Mongo::ASCENDING]]
      
      # Use a special all method which gets shared buckets as well ???
      if args.include?(:refresh) && args[:refresh]
        @objects = SmObject.where(query,sort)
      else
        @objects ||= SmObject.where(query,sort)
      end
      @objects
    end
    
    def objects_by_prefix(args = {})
      args.include_only( :max_keys, :prefix, :marker, :base_only, :delimiter, :marked_for_delete, :sort )
      
      base_only = args.has_key?(:base_only) ? args[:base_only] : true
      marker = args.has_key?(:marker) ? args[:marker] : nil
      delimiter = args.has_key?(:delimiter) ? args[:delimiter] : '/'
      
      query = {}
      query[:prefix] = args[:prefix] if args.has_key?(:prefix)
      query[:delete_marker] = true if args.has_key?(:marked_for_delete) && args[:marked_for_delete]
      
      object_list = self.objects(:refresh => true, :query => query)
    end
    
    def versioning_from_xml(xml)
      v = Hash.from_xml(xml)
      raise S3Exception.new(:InvalidRequest, 'Versioning tags not found.') unless v.has_key?('VersioningConfiguration')
      case v['VersioningConfiguration']['Status']
      when "Enabled"
        self.is_versioning = true
      when "Suspended"
        self.is_versioning = false
      else
        raise S3Exception.new(:InvalidRequest, 'Invalid status received.')
      end
      save!
    end
         
    # # Conforming to DNS requirements
    # validates :name, :length => { :in => 3..255 }
    # validates :name, :format => { :with => /^([a-zA-Z0-9]|[a-zA-Z0-9][a-zA-Z0-9\-]{0,61}[a-zA-Z0-9])(\.([a-zA-Z0-9]|[a-zA-Z0-9][a-zA-Z0-9\-]{0,61}[a-zA-Z0-9]))*$/ }
    # validates :name, :presence => true
    # validates :name, :uniqueness => true
      
  end
end