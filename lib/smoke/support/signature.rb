module Smoke
  class Signature
    
    attr_reader :request, :signature
    attr_reader :content_md5, :content_type, :date, :bucket, :path
    attr_reader :method, :resources, :amz_headers, :secret_key, :expires
    
    def initialize(secret, options = {})
      options.include_only(:secret_key, :method, :type, :md5, :bucket, 
        :path, :amz_headers, :params, :expires, :date)
      @secret_key = secret
      @method = options[:method] || "GET"
      @content_md5 = options[:md5] || ""
      @content_type = options[:type] || ""
      @bucket = options[:bucket] || ""
      @path = options[:path] || "/"
      @date = options[:date] || DateTime.now.to_z
      @amz_headers = options[:amz_headers] || {}
      @params = options[:params] || {}
      @expires = options[:expires] || nil
      @signature = nil
    end
    
    def to_s
      @signature || sign
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
      # puts "StringToSign: " + string_to_sign  
      digest = OpenSSL::Digest::Digest.new('sha1')
      signed_string = OpenSSL::HMAC.digest(digest, @secret_key, string_to_sign)
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
      for key in (@params || {}).keys.sort
        if %w{acl expires location logging notification partNumber policy 
              requestPayment reponse-cache-control response-content-disposition 
              response-content-encoding response-content-language 
              response-content-type response-expires torrent uploadId uploads 
              versionId versioning versions website auth user users}.include?(key)
          c << "#{key}#{"=#{@params[key]}" unless @params[key].nil?}&"
        end
      end
      c.chop!
      c
    end
  end
end