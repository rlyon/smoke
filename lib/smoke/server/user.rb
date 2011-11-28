module Smoke
  module Server
    class User < ActiveRecord::Base
      has_many :buckets, :dependent => :destroy
      has_many :acls, :dependent => :destroy
      has_many :assets, :dependent => :destroy
      
      after_save :create_default_buckets
      
      validates :access_id, :presence => true
      validates :access_id, :length => { :is => 20 }
      validates :access_id, :format => { :with => /[a-zA-Z0-9]/ }
      validates :access_id, :uniqueness => true
      
      validates :secret_key, :presence => true
      validates :secret_key, :length => { :is => 40 }
      
      validates :username, :uniqueness => true
      validates :username, :length => { :in => 4..8 }
      validates :username, :presence => true
      
      validates :display_name, :length => { :in => 2..40 }
      validates :display_name, :presence => true
      validates :display_name, :format => { :with => /[a-zA-Z ]/ }
      
      validates :email, :presence => true
      validates :email, :format => { :with => /\A([^@\s]+)@((?:[-a-z0-9]+\.)+[a-z]{2,})\Z/i }
      validates :email, :uniqueness => true
      
      # The object have a permissions method, and acl must be a symbol representation of the permission
      def has_permission_to( acl, obj )
        obj.permissions(self).include? acl
      end
      
      def has_valid_status?
        self.is_active
      end
      
      def all_my_buckets
        buckets = self.buckets.find(:all)
        shared_buckets = Bucket.find_all_through_acl(self)
        shared_buckets.each { |bucket| buckets << bucket }
        buckets.sort! { |a,b| a.name <=> b.name }
      end

      private
      def create_default_buckets
        bucket = self.buckets.new(:name => self.username)
        bucket.save!
        bucket = self.buckets.new(:name => "#{self.username}-logs")
        bucket.save!
      end
      
    end
  end
end