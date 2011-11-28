module Smoke
  module Server
    class XmlParser
      attr_reader :errors, :xml
      
      def initialize(xml)
        @errors = []
        @xml = xml
      end

      def contains_text?(tag, value)
        body = Nokogiri::XML(@xml)
        body.search(tag).each do |element|
          return true if element.text == value
        end
        return false
      end

      def parse_grants
        grants = {} 
        body = Nokogiri::XML(@xml)
        body.search('Grant').each do |grant|
          permission = grant.css('Permission').text
          grantee = grant.search('Grantee')
          case grantee.first.attributes['type'].value
          when "CanonicalUser"
            id = grantee.css('ID').text
            if id.empty?
              @errors << { :key => :UserKeyMustBeSpecified, :message => 'Unspecified user key.' }
              return nil
            end
            user = User.find_by_access_id(id)
            if user.nil?
              @errors << { :key => :InvalidAccessKeyId, :message => 'Invalid access key' }
              return nil
            end
            grants[user.id.to_s] = [] unless grants.has_key?(user.id)
            grants[user.id.to_s] << permission.downcase
          when "AmazonCustomerByEmail"
            email = grantee.css('EmailAddress').text
            users = User.where(:email => email)
            if users.empty?
              @errors << { :key => :UnresolvableGrantByEmailAddress, :message => "Could not find user for acl put request" }
              return nil
            elsif users.size > 2
              @errors << { :key => :AmbiguousGrantByEmailAddress, :message => 'Ambiguous email address for acl put request.' }
              return nil
            end
            grants[users.first.id.to_s] = [] unless grants.has_key?(users.first.id)
            grants[users.first.id.to_s] << permission.downcase
          when "Group"
            # Not implemented yet
            @errors << { :key => :InternalError, :message => "Unknown grantee type: #{grantee.first.attributes['type'].value}" }
            return nil
          else
            @errors << { :key => :InternalError, :message => "Unknown grantee type: #{grantee.first.attributes['type'].value}" }
            return nil
          end
        end
        return grants
      end

    end
  end
end