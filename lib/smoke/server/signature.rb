module Smoke
  module Server
    class Signature
      
      attr_reader :request
      attr_accessor :content_md5, :content_type, :date, :bucket, :path
      attr_accessor :method, :resources, :amz_headers, :user, :expires
      
      def initialize(request)
        @request = request
      end
      
      def sign
        string_to_sign = @method.upcase + "\n"
        string_to_sign << @content_md5 + "\n"
        string_to_sign << @content_type + "\n"
        if @expires.nil?
          string_to_sign << @date unless @amz_headers.has_key?('x-amz-date')
          string_to_sign << "\n"
        else
          string_to_sign << @expires + "\n"
        end
        string_to_sign << cannonicalized_amz_headers
        string_to_sign << cannonicalized_resources
        puts "StringToSign: " + string_to_sign  
        digest = OpenSSL::Digest::Digest.new('sha1')
        signed_string = OpenSSL::HMAC.digest(digest, @user.secret_key, string_to_sign)
        @signature = Base64.encode64(signed_string).chomp!
      end
      
      def cannonicalized_amz_headers
        c = ""
        (@amz_headers.sort {|x, y| x[0] <=> y[0]}).each do |key,value|
          c << "#{key}:#{value.join(',')}\n"
        end
        c
      end
      
      def cannonicalized_resources
        unless @bucket.empty?
          c = '/' + @bucket
        else
          c = ""
        end
        c << @path
        c << "?"
        for key in (@resources || {}).keys.sort
          if %w{acl expires location logging notification partNumber policy requestPayment reponse-cache-control
                response-content-disposition response-content-encoding response-content-language
                response-content-type response-expires torrent uploadId uploads versionId versioning
                versions website}.include?(key)
            c << "#{key}#{"=#{@resources[key]}" unless @resources[key].nil?}&"
          end
        end
        c.chop!
        c
      end
    end
  end
end