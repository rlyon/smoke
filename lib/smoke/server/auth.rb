require 'pp'
module Smoke
  module Server
    class Auth
      def initialize(app, config = {})
        @app = app
        @config = config
      end
      
      def call(env)
        request = Request.new(env)
        # Assign the request ID that will be used throughout the transaction    
        request.env['smoke.request_id'] = String.hex :length => 32
        request.env['smoke.request_token'] = String.random :length => 48
        
        # Bypass signature for https password authentication in post
        return @app.call(env) if env['REQUEST_METHOD'] == "POST" && env['REQUEST_PATH'] == "/"
        
        # I should use a regex to handle all finle that a browser expects
        return [404,{},[]] if env['REQUEST_PATH'] == "/favicon.ico"
        
        return error(env, :MissingSecurityHeader) unless request.has_auth?
        request.find_user
        return error(env, :NotSignedUp) unless request.has_user?
        return error(env, :AccountProblem) unless request.env['smoke.user'].is_active?
        pp request
        if request.valid?
          return @app.call(env)
        else
          return error(env, :SignatureDoesNotMatch)
        end
      end
      
      private 
      def error(env, error)
        response = responses[error]
        @code = error.to_s
        @resource = env['smoke.path']
        @status = response[0]
        @message = response[1]
        file = File.dirname(__FILE__) + '/../../../views/error.erb'
        template = ::ERB.new(File.read(file))
        body = template.result(binding)
        content = [ body ]
        header = { 
          "Content-Length" => body.empty? ? "0" : body.size.to_s,
          "Content-Type" => "plain/text",
          "Connection" => "close",
          "Date" => Time.now.gmtime.to_z,
          "Server" => "#{SERVER} - #{CODENAME}",
          "x-amz-request-id" => env['smoke.request_id'],
          "x-amz-id-2" => env['smoke.request_token']
        }
        [@status,header,content]
      end
      
      def responses
        {
          :AccessDenied => [403,"Access Denied"],
          :AccountProblem => [403,"There is a problem with your AWS account that prevents the operation from completing successfully. Please contact us."],
          :CredentialsNotSupported => [400, "The request does not support credentials."],
          :InternalError => [500, "We encountered an internal error.  Please try again."],
          :InvalidAccessKeyId => [403, "The access key ID you provided does not exist in our records."],
          :InvalidSecurity => [403, "The provided security credentials are not valid."],
          :MissingSecurityHeader => [400, "Your request was missing a required header."],
          :NotSignedUp => [403, "Your account is not signed up for the service."],
          :NotFound => [403, "Not Found."],
          :SignatureDoesNotMatch => [403, "The request signature we calculated does not match the signature you provided."],
        }
      end
      
      # invalid_access_key_id
      # missing_security_header
      # account_problem
      
      class Request < Rack::Request
        HTTP_HEADER_PREFIX = 'HTTP_'
        AMZ_HEADER_PREFIX = 'HTTP_X_AMZ_'
        
        def initialize(env)
          super(env)
          parse_headers
          parse_bucket_and_path do |bucket,path|
            env['smoke.bucket'] = bucket
            env['smoke.path'] = path
          end
          mangle_request if is_dns_style_bucket?
        end
        
        def valid?
          s = Signature.new( env['smoke.user'].secret_key,
            :method => env['REQUEST_METHOD'],
            :md5 => env['HTTP_CONTENT_MD5'] || nil,
            :type => env['CONTENT_TYPE'] || "",
            :bucket => env['smoke.bucket'],
            :path => env['smoke.path'],
            :date => amz_date,
            :params => params,
            :amz_headers => env['smoke.amz_headers'],
            :expires => params['Expires'] || nil,
          )
          s.sign == signature
        end
        
        def amz_date
          if env.has_key?('smoke.amz_headers') && env['smoke.amz_headers'].has_key?('x-amz-date')
            env['smoke.amz_headers']['x-amz-date'][0]
          else
            env['HTTP_DATE']
          end
        end
        
        def is_dns_style_bucket?
          !(host =~ /^#{SMOKE_CONFIG['host']}/)
        end
        
        def find_user
          user = User.find_by_access_id(access_id)
          unless user.nil?
            env['smoke.user'] = user
            env['smoke.access_id'] = user.access_id
          else
            env['smoke.user'] = nil
            env['smoke.access_id'] = nil
          end
        end
        
        def parse_headers
          headers = {}
          amz_headers = {}
          meta_count = 0

          env.each do |key,value|
            if key =~ /^#{AMZ_HEADER_PREFIX}/
              len = AMZ_HEADER_PREFIX.length
              keyname = "x-amz-#{(key.downcase.gsub('_','-'))[len..-1]}"
              unless amz_headers.include?(keyname)
                amz_headers[keyname] = []
              end
              amz_headers[keyname] << value
              # add error if count is to 
              # raise Smoke::S3::Exceptions::MetadataTooLarge.new('Metadata headers are beyond the max allowed.') if
            elsif key =~ /^#{HTTP_HEADER_PREFIX}/
              len = HTTP_HEADER_PREFIX.length
              keyname = (key.downcase.gsub('_','-'))[len..-1]
              headers[keyname] = value
            end
          end
          env['smoke.resource_headers'] = headers
          env['smoke.amz_headers'] = amz_headers
        end
        
        def credentials
          unless params.has_key?('AWSAccessKeyId')
            @credentials ||= env['HTTP_AUTHORIZATION'].split[1].split(/:/,2) unless env['HTTP_AUTHORIZATION'].nil?
          else
            @credentials ||= [params['AWSAccessKeyId'],params['Signature']]
          end
        end
        
        def access_id
          # pp credentials
          credentials.first
        end
        
        def signature
          credentials.last
        end
        
        def has_auth?
          if env['HTTP_AUTHORIZATION']
            true
          elsif params['AWSAccessKeyId'] && params['Signature']
            true
          else
            false
          end
          #!env['HTTP_AUTHORIZATION'].nil? || !(params['AWSAccessKeyId'].nil? || params['Signature'].nil?)
        end
        
        def has_user?
          !env['smoke.user'].nil?
        end
        
        def parse_bucket_and_path
          # No bucket has been specified as dns style or alternate path style
          unless host =~ /^#{SMOKE_CONFIG['host']}/
            bucket = host.split('.')[0]
            path = env['REQUEST_PATH'].empty? ? '/' : env['REQUEST_PATH']
          else # the bucket must be part of the path...
            unless env['REQUEST_PATH'] == "/"
              bucket = env['REQUEST_PATH'].split('/')[1]
              # puts @request.path
              # puts bucket
              path = env['REQUEST_PATH'].gsub("/" + bucket, "")
            else
              bucket = ""
              path = '/'
            end
          end
          yield(bucket,path)
        end
        
        # Converts all the environment to the old dns style paths for sinatra
        def mangle_request
          protocol = env['rack.url_scheme']
          bucket = host.split('.')[0]
          mod_path = "/#{bucket}#{env['REQUEST_PATH']}"
          uri = "#{protocol}://#{env['SERVER_NAME']}#{mod_path}?#{env['QUERY_STRING']}"
          env['PATH_INFO'] = mod_path
          env['REQUEST_PATH'] = mod_path
          env['REQUEST_URI'] = uri
        end
      end
      
    end
  end
end