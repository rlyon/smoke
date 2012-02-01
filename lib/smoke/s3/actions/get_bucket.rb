module Smoke
  module S3
    class App < Sinatra::Base
      
      # Get operations on the bucket
      get '/:bucket/?' do |bucket|
        setup(:bucket => bucket)
        
        if params.has_key?('versioning')
          erb :get_bucket_versioning
        
        # Returns the bucket wide access control list  
        elsif params.has_key?('acl')
          @obj = @bucket
          @acls = @bucket.acls
          erb :get_access_control_list
          
        # Returns the payment configuration.  Currently not used.
        elsif params.has_key?('requestPayment')
          respond_error(:NotImplemented)
        # Returns the website configuration for the bucket.  Currently not used.
        elsif params.has_key?('website')
          respond_error(:NotImplemented)
        # Returns the location of the bucket.  Currently not used.
        elsif params.has_key?('location')
          respond_error(:NotImplemented)
        # Return the logging status of the bucket.
        elsif params.has_key?('logging')
          erb :get_bucket_logging
        elsif params.has_key?('versions')
          respond_error(:NotImplemented)
        # Return the notification status of the bucket.  Not implemented.
        elsif params.has_key?('notification')
          respond_error(:NotImplemented)
        # List out the bucket objects
        else
          @delimited = params.has_key?('delimiter') ? true : false
          @max_keys = params.has_key?('max-keys') ? params['max-keys'] : SMOKE_CONFIG['default_max_keys']
          @prefix = params.has_key?('prefix') ? params['prefix'] : nil

          unless @delimited
            @objects = @bucket.objects :prefix => @prefix
            @common_prefixes = []
          else
            @objects = @bucket.objects :prefix => @prefix
            @common_prefixes = @bucket.common_prefixes @prefix
          end
          
          erb :get_bucket
        end
      end
      
    end
  end
end