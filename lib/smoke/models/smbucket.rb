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
    
    def common_prefixes(prefix = '')
      prefix = '' if prefix.nil?
      
      prefixes = []
      rx = Regexp.new('^' + prefix + '[a-zA-Z0-9_\.\-]*\/')
      objects(:use_cache => false, :prefix => prefix, :only_common => true).each do |object|
        p = rx.match(object.object_key).to_s
        prefixes << p unless p.empty? || prefixes.include?(p)
      end
      prefixes
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
      args.include_only(:use_cache, :prefix, :sort, :recursive, :only_common)
      
      recurse = args.has_key?(:recursive) ? args[:recursive] : true
      only_common = args.has_key?(:only_common) ? args[:only_common] : false
      prefix = args.has_key?(:prefix) && !args[:prefix].nil? ? args[:prefix] : ''
      use_cache = args.include?(:use_cache) ? args[:use_cache] : false
      
      allowed_chars = '[a-zA-Z0-9\.\-\_]'
      if only_common
        regex_end = '*\/'
      else
        regex_end = recurse ? '' : '+$'
      end
      
      rx = Regexp.new('^' + prefix + allowed_chars + regex_end)
      
      # Update the query with the bucket id
      query = {}
      query[:object_key] = rx 
      query[:bucket_id] = self.id
      
      # Set the sorting direction... put this back in connector ???
      sort = [["key", Mongo::ASCENDING]]
      
      # Use a special all method which gets shared buckets as well ???
      if use_cache
        @objects_cache ||= SmObject.where(query)
      else
        @objects_cache = SmObject.where(query)
      end
      @objects_cache
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