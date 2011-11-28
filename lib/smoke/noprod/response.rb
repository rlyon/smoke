module Smoke
  module Server
    class AbstractResponse
      attr_reader :status, :message, :body, :env
      
      def initialize(env, key = :UnknownResponse, resource = "/")
        response = responses[key]
        @status = response[0]
        @message = response[1]
        @env = env
      end
      
      def responses
        {
          :UnknownResponse => [501, "Unable to respond.  Response not found."]
        }
      end
      
      def respond(tmpl = "error")
        file = File.dirname(__FILE__) + '/../../../../views/' + tmpl + '.erb'
        template = ::ERB.new(File.read(file))
        @body = template.result(binding)
        { 'status' => @status,
          'header' => @message.empty? ? no_content : header,
          'body' => @body
        }
      end

      def respond_to_sinatra(app, tmpl)
        # use sinatras header methods to set the header...
        file = File.dirname(__FILE__) + '/../../../../views/' + tmpl + '.erb'
        template = ::ERB.new(File.read(file))
        @body = template.result(binding)
        
        status @status
        headers header
        body @body
      end
      
      def respond_to_rack(tmpl)
        file = File.dirname(__FILE__) + '/../../../../views/' + tmpl + '.erb'
        template = ::ERB.new(File.read(file))
        @body = template.result(binding)
        [@status,@message.empty? ? no_content : header,[@body]]
      end
      
      private

      def header( headers = {} )
        header = { 
          "Content-Length" => @body.empty? ? "0" : @body.size.to_s,
          "Content-Type" => headers[:content_type] ? headers[:content_type] : "plain/text",
          "Connection" => headers[:connection] ? headers[:connection] : "close",
          "Date" => Time.now.gmtime.strftime("%Y-%m-%dT%H:%M:%S.000Z"),
          "Server" => "#{SERVER} - #{CODENAME}",
          "x-amz-request-id" => @env['smoke.request_id'],
          "x-amz-id-2" => @env['smoke.request_token']
        }
        header["x-amz-version-id"] = headers[:version_id] if headers.include?(:version_id)
        header["ETag"] = headers[:etag] if headers.include?(:etag)
        header["x-amz-delete-marker"] = headers[:delete_marker] if headers.include?(:delete_marker)
        header["Location"] = headers[:location] if headers.include?(:location)
        header["Last-Modified"] = headers[:modified] if headers.include?(:modified)
        header
      end
      
      def no_content( headers = {} )
        header = { "Content-Length" => "0",
                    "Connection" => "close",
                    "Date" => Time.now.gmtime.strftime("%Y-%m-%dT%H:%M:%S.000Z"),
                    "Server" => "#{SERVER} - #{CODENAME}",
                    "x-amz-request-id" => @env['smoke.request_id'],
                    "x-amz-id-2" => @env['smoke.request_token']
        }
        header
      end
    end
  end
end