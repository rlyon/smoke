module Smoke
  module Web
    class Connection
      attr_reader :connection, :uri, :port, :host, :url
      def initialize(options = {})
        params = options.has_key?('params') ? options['params'] : {}
        host = options.has_key?('host') ? options['host'] : 'localhost'
        path = options.has_key?('path') ? options['path'] : ''
        port = options.has_key?('port') ? options['port'] : 80
        @url = "http://#{host}#{path}"
        unless params.empty?
          @url << "?"
          params.each do |key,value|
            @url << "#{key.to_s}=#{value}&"
          end
          @url.chop!
        end
        @uri = URI(url)
        @host = host
        @port = port
      end
      
      def get
        Net::HTTP.start(@uri.host, @uri.port) do |http|
          request = Net:HTTP::Get.new uri.request_uri
          request.add_field 'Authorization', sign_request
          response = http.request request
        end
      end
      
      def sign_request
        s = Signature.new
      end
        
        