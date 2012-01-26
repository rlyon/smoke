module Smoke
    class User < Smoke::Model::Base
      
      attr_reader :enc_password, :active, :activated_at, :created_at, :updated_at
      attr_accessor :username, :access_id, :secret_key, :display_name, :email
      attr_accessor :password, :password_confirmation
      
      def acls
        nil
      end
      
      def active?
        nil
      end
      
      def activate
        nil
      end
      
      def buckets
        nil
      end
      
      def objects
        nil
      end
      
      def update( args = {} )
        nil
      end
      
      
      
      
      # has_many :buckets, :dependent => :destroy
      # has_many :acls, :dependent => :destroy
      # has_many :assets, :dependent => :destroy
#       
      # before_save :encrypt_password
      # after_create :create_default_buckets
#       
      # validates :access_id, :presence => true
      # validates :access_id, :length => { :is => 20 }
      # validates :access_id, :format => { :with => /[a-zA-Z0-9]/ }
      # validates :access_id, :uniqueness => true
#       
      # validates :secret_key, :presence => true
      # validates :secret_key, :length => { :is => 40 }
#       
      # validates :username, :uniqueness => true
      # validates :username, :length => { :in => 4..8 }
      # validates :username, :presence => true
#       
      # validates :display_name, :length => { :in => 2..40 }
      # validates :display_name, :presence => true
      # validates :display_name, :format => { :with => /[a-zA-Z ]/ }
#       
      # validates :email, :presence => true
      # validates :email, :format => { :with => /\A([^@\s]+)@((?:[-a-z0-9]+\.)+[a-z]{2,})\Z/i }
      # validates :email, :uniqueness => true
#       
      # validates :password, :presence => true, :on => :create
#       
      # # The object have a permissions method, and acl must be a symbol representation of the permission
      # def has_permission_to( acl, obj )
        # obj.permissions(self).include? acl
      # end
#       
      # def has_valid_status?
        # self.is_active
      # end
#       
      # def all_my_buckets
        # buckets = []
        # owned_buckets = self.buckets.find(:all)
        # shared_buckets = Bucket.find_all_through_acl(self)
        # owned_buckets.each { |bucket| buckets << bucket unless bucket.nil? }
        # shared_buckets.each { |bucket| buckets << bucket unless bucket.nil? }
        # buckets.sort! { |a,b| a.name <=> b.name }
      # end
#       
      # def password_salt
        # self.enc_password.split(':').first
      # end
#       
      # def password_hash
        # self.enc_password.split(':').last
      # end
#       
      # class << self
        # def authenticate(identity, password)
          # if identity =~ /\A([^@\s]+)@((?:[-a-z0-9]+\.)+[a-z]{2,})\Z/i
            # user = find_by_email(identity)
          # else
            # user = find_by_username(identity)
          # end
#           
          # if user && user.password_hash == BCrypt::Engine.hash_secret(password, user.password_salt)
            # user
          # else
            # nil
          # end
        # end
      # end
# 
      # private
      # def encrypt_password
        # if password.present?
          # salt = BCrypt::Engine.generate_salt
          # hash = BCrypt::Engine.hash_secret(password, salt)
          # self.enc_password = "#{salt}:#{hash}"
        # end
      # end
#       
      # def create_default_buckets
        # bucket = self.buckets.new(:name => self.username)
        # bucket.save!
        # bucket = self.buckets.new(:name => "#{self.username}-logs")
        # bucket.save!
      # end
      
  end
end