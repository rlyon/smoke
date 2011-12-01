module Smoke
  module Server
    class Acl < ActiveRecord::Base
      attr_reader :errs
      belongs_to :bucket
      belongs_to :user
      belongs_to :asset
      
      #validates :email, :presence => true
      validates :permission, :presence => true
      
      class << self
        def from_xml(xml,obj,&block)
          raise S3Exception.new(:InternalError, "Object does not respond to acls") unless obj.respond_to?(:acls)
          raise S3Exception.new(:InternalError, "Object does not respond to remove_user_acls") unless obj.respond_to?(:remove_acls)
          raise S3Exception.new(:InternalError, "Object does not respond to user_id") unless obj.respond_to?(:user_id)
          
          body = Nokogiri::XML(xml)
          obj.remove_acls
          
          body.search('Grant').each do |grant|
            permission = grant.css('Permission').text
            grantee = grant.search('Grantee')
            acl = obj.acls.new(:permission => permission)
            case grantee.first.attributes['type'].value
            when "CanonicalUser"
              id = grantee.css('ID').text
              raise S3Exception.new(:UserKeyMustBeSpecified, 'Unspecified user key.') if id.empty?
              user = User.find_by_access_id(id)
              raise S3Exception.new(:InvalidAccessKeyId, 'Invalid access key') if user.nil?
              acl.user_id = user.id
            when "AmazonCustomerByEmail"
              email = grantee.css('EmailAddress').text
              users = User.where(:email => email)
              raise S3Exception.new(:UnresolvableGrantByEmailAddress, "Could not find user for acl put request") if users.empty?
              raise S3Exception.new(:AmbiguousGrantByEmailAddress, "Ambiguous email address for acl put request.") if users.length > 1
              user = users.first
              acl.user_id = user.id
            when "Group"
              raise S3Exception.new(:NotImplemented, "Group acl assignments are not yet implemented")
            else
              raise S3Exception.new(:InternalError, "Unknown grantee type: #{grantee.first.attributes['type'].value}")
            end
            
            # The owner of the object automatically gets full access.  This is non-negotiable so just shut the hell
            # up about it.
            # Can I get this conditional before the bottom?  I only waste one itteration through the loop, but still...
            unless obj.user_id == user.id
              yield(acl)
            end
          end
        end
      end
      
    end
  end
end