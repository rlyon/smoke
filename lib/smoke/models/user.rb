module Smoke
  class User
    include Smoke::Document
    
    attr_accessor :password, :password_confirmation, :password_hash, :password_salt
    key :username, String
    key :display_name, String
    key :email, String
    key :access_id, String, :default => String.random(:length => 20)
    key :secret_key, String, :default => String.random(:length => 40)
    key :enc_password, String
    key :active, Boolean, :default => false
    key :activated_at, Time
    key :max_buckets, Integer, :default => 2
    key :role, String, :default => "standard"
    
    def acls
      nil
    end

    def activate
      self.active = true
      self.save
    end
    
    def buckets(args = {})
      args.include_only(:use_cache)
      use_cache = args.include?(:use_cache) ? args[:use_cache] : false
      # Use a special all method which gets shared buckets as well???
      if use_cache
        buckets ||= SmBucket.where(:user_id => self.id)
      else
        buckets = SmBucket.where(:user_id => self.id)
      end
      @buckets_cache = (buckets + self.shared_buckets)
    end
    
    def bucket_names
      @bucket_names_cache = buckets(:use_cache => false).inject([]) do |ret,bucket|
        ret << bucket.name
      end
    end
    
    def create_default_buckets
      # Would be really nice as a callback...  Don't know those yet
      unless self.has_bucket?(self.username)
        bucket = SmBucket.new(:user_id => self.id, :name => self.username)
        bucket.save
      end
      unless self.has_bucket?("#{self.username}-logs")
        bucket = SmBucket.new(:user_id => self.id, :name => "#{self.username}-logs")
        bucket.save
      end
      # Return the buckets and reload the cache
      self.buckets(:use_cache => false)
    end
    
    def deactivate
      self.active = false
      self.save
    end
    
    def has_permission_to?(acl, obj)
      obj.permissions(self).include? acl
    end
    
    def has_bucket?(name)
      bucket_names.include?(name)
    end
    
    def objects
      args.include_only(:use_cache)
      # Use a special all method which gets shared buckets as well
      if args.include?(:use_cache) && !args[:use_cache]
        @objects = SmObject.all(:user_id => self.id)
      else
        @objects ||= SmObject.all(:user_id => self.id)
      end
      @objects
    end
    
    def password_salt
      self.enc_password.split(':').first
    end
    
    def password_hash
      self.enc_password.split(':').last
    end
    
    def save
      create_default_buckets
      encrypt_password
      super
    end
    
    def shared_buckets
      buckets = []
      acls = Acl.where(:user_id => self.id)
      acls.each do |acl|
        bucket = SmBucket.find(:_id => acl.obj_id)
        buckets << bucket unless bucket.nil? || buckets.include?(bucket)
      end
      buckets
    end
    
    def shared_objects
      objects = []
      acls = Acl.where(:user_id => self.id)
      acls.each do |acl|
        object = SmObject.find(:_id => acl.obj_id)
        objects << object unless object.nil? || objects.include?(object)
      end
      objects
    end
    
    class << self
      def authenticate(identity, password)
        if identity =~ /\A([^@\s]+)@((?:[-a-z0-9]+\.)+[a-z]{2,})\Z/i
          user = find_by_email(identity)
        else
          user = find_by_username(identity)
        end
        
        if user && user.password_hash == BCrypt::Engine.hash_secret(password, user.password_salt)
          user
        else
          nil
        end
      end
    end
    
    private
      def encrypt_password
        unless password.nil?
          salt = BCrypt::Engine.generate_salt
          hash = BCrypt::Engine.hash_secret(password, salt)
          self.enc_password = "#{salt}:#{hash}"
        end
      end
    
    
    # has_many :buckets, :dependent => :destroy
    # has_many :acls, :dependent => :destroy
    # has_many :assets, :dependent => :destroy
    # before_save :encrypt_password
    # after_create :create_default_buckets
    # validates :access_id, :presence => true
    # validates :access_id, :length => { :is => 20 }
    # validates :access_id, :format => { :with => /[a-zA-Z0-9]/ }
    # validates :access_id, :uniqueness => true
    # validates :secret_key, :presence => true
    # validates :secret_key, :length => { :is => 40 }
    # validates :username, :uniqueness => true
    # validates :username, :length => { :in => 4..8 }
    # validates :username, :presence => true
    # validates :display_name, :length => { :in => 2..40 }
    # validates :display_name, :presence => true
    # validates :display_name, :format => { :with => /[a-zA-Z ]/ }
    # validates :email, :presence => true
    # validates :email, :format => { :with => /\A([^@\s]+)@((?:[-a-z0-9]+\.)+[a-z]{2,})\Z/i }
    # validates :email, :uniqueness => true
    # validates :password, :presence => true, :on => :create

  end
end