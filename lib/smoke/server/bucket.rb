module Smoke
  module Server
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
    class Bucket < ActiveRecord::Base
      belongs_to :user
      has_many :acls, :dependent => :destroy
      has_many :assets, :dependent => :destroy
      accepts_nested_attributes_for :assets
      
      scope :public_read, where(:visibility => 'public')
      
      attr_reader :truncated
      
      # Conforming to DNS requirements
      validates :name, :length => { :in => 3..255 }
      validates :name, :format => { :with => /^([a-zA-Z0-9]|[a-zA-Z0-9][a-zA-Z0-9\-]{0,61}[a-zA-Z0-9])(\.([a-zA-Z0-9]|[a-zA-Z0-9][a-zA-Z0-9\-]{0,61}[a-zA-Z0-9]))*$/ }
      validates :name, :presence => true
      validates :name, :uniqueness => true
      
      def assign_acls(acl_arr)
        acl_arr.each do |acl|
          acl.bucket_id = self.id
          acl.save!
        end
      end
      
      def assign_acl(acl)
        acl.bucket_id = self.id
        acl.save!
      end
      
      def has_assets?
        self.assets.empty? == false
      end
      
      def has_permitted_assets?(user)
        !self.assets_attributes.where(:user_id => user.id)
      end
      
      def permissions(user)
        return [:full_control,:read,:write,:read_acl,:write_acl] if self.user.id == user.id
        a = self.acls.where(:user_id == user.id)
        if a.empty?
          # check to see if there are assets which are available
          return [:read] if self.has_permitted_assets?(user)
        else
          a.map {|acl| acl.permission.to_sym}
        end
      end
      
      def create_acl!(user, acl)
        a = Acl.new(:user_id => user.id, :bucket_id => self.id, :permission => acl)
        a.save!
      end
      
      def destroy_if_empty
        if self.has_assets?
          ## Ho to handle this
        end
        self.destroy
      end
      
      def remove_acls(user_id)
        a = self.acls.where(:user_id => user_id)
        a.each do |acl|
          acl.destroy
        end
      end
      
      def remove_acls
        Acl.where(:bucket_id => self.id).delete_all
      end
      
      def common_prefixes(args = {})
        unless args.include_only?( :prefix, :delimiter )
          raise "Invalid parameters in find_filtered"
        end
        prefix = args.has_key?(:prefix) ? args[:prefix] : nil
        delimiter = args.has_key?(:delimiter) ? args[:delimiter] : nil
        
        prefixes = []
        asset_list = find_filtered_assets(:delimiter => delimiter, :prefix => prefix, :base_only => false)
        asset_list.each do |asset|
          dir = asset.dirname(delimiter,prefix)
          prefixes << dir if !dir.nil?
        end
        
        prefixes.inject([]) do |arr,dir|
          path = prefix + dir unless prefix.nil?
          path ||= dir
          arr << path unless arr.include?(path)
          arr
        end
      end
      
      def find_filtered_assets(args = {})
        unless args.include_only?( :max_keys, :prefix, :marker, :base_only, :delimiter, :marked_for_delete )
          raise "Invalid parameters in find_filtered"
        end

        base_only = args.has_key?(:base_only) ? args[:base_only] : true
        prefix = args.has_key?(:prefix) ? args[:prefix] : nil
        delimiter = args.has_key?(:delimiter) ? args[:delimiter] : '/'
        marker = args.has_key?(:marker) ? args[:marker] : nil
        max_keys = args.has_key?(:max_keys) ? args[:max_keys] : SMOKE_CONFIG['default_max_keys']
        delete_marker = args.has_key?(:marked_for_delete) ? args[:marked_for_delete] : false

        if prefix.nil?
          asset_list = Asset.find(:all, :conditions => ["bucket_id = ? AND delete_marker = ?", self.id, delete_marker])
        else
          asset_list = Asset.find(:all, :conditions => ["bucket_id = ? AND delete_marker = ? AND key LIKE ?", self.id, delete_marker, "#{prefix}%"])
        end

        if base_only
          asset_list = asset_list.inject([]) do |arr,asset|
            base = asset.basename(delimiter,prefix)
            # puts "BASE: " + base unless base.nil?
            arr << asset unless base.nil?
            arr
          end
        end

        unless marker.nil?
          asset_list = asset_list.inject([]) do |arr,asset|
            base = asset.basename(delimiter,prefix)
            arr << asset if !base.nil? && base > marker
            arr
          end
        end
        
        @truncated = true if asset_list.length > max_keys.to_i
        asset_list = asset_list[0..max_keys.to_i]
      end

      def find_or_create_asset_by_key(key)
        asset = self.assets.where(:key => key).first
        asset ||= self.assets.new(:key => key, :user_id => self.user.id)
      end
      
      def logging_from_xml(xml)
        l = Hash.from_xml(xml)
        raise S3Exception.new(:InvalidRequest, 'Logging tags not found.') unless v.has_key?('BucketLoggingStatus')
        if l.has_key?('LoggingEnabled')
          self.is_logging = true
        else
          self.is_logging = false
        end
        save!
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
      
      class << self
        def find_all_through_acl(user)
          acls = Acl.where(:user_id => user.id)          
          acls.inject([]) do |arr,acl|
            bucket = nil
            unless acl.bucket.nil?
              bucket = acl.bucket
            else
              bucket = acl.asset.bucket
            end
            arr << bucket unless !bucket.nil? && arr.include?(bucket)
            arr
          end
        end
      end
      
    end
  end
end