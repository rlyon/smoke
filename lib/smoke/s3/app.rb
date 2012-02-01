module Smoke
  module S3
    class App < Sinatra::Base
      helpers Sinatra::ResponseHelper
      helpers Sinatra::FetchHelper
      
      set :views, [File.dirname(__FILE__) + '/../../../views']
      
      # Put service to update user attributes or create a user if that user does
      # not already exist.  Users will have the ability to update their own profiles 
      # and attributes and administrators will have the ability to create new users
      # and modify other users. 
      put '/' do
        if params.has_key?('user')
          # update user details if user is admin or self, create if admin
          respond_error(:NotImplemented)
        # The only puts you can do on the service is updating/adding a user
        else
          respond_error(:InvalidRequest)
        end
      end
      
      # Initial authentication service used for administrative services, user updating
      # and creation.  Basically, this post allows an external interface to authenticate
      # via [username/email] and a standard password and returns the access ID and 
      # key back so all requests can include the standard auth headers
      post '/' do
        @user = User.authenticate(params[:username],params[:password])
        if @user
          erb :user
        else
          respond_error(:AccessDenied)
        end
      end
      
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
      
      # Give me HEAD!
      head '/:bucket/*' do |bucket,object|
        setup :bucket => bucket, :object => object
        respond_ok(nil,
          { :etag => @object.etag, 
            :modified => @object.updated_at, 
            :size => @object.size, 
            :content_type => @object.content_type
          }
        )
      end
      
      # Get operations on the object (asset)
      get '/:bucket/*' do |bucket,path|
        allow_params 'torrent', 'acl', 'bucket'
        setup :bucket => bucket, :object => path
        
        if params.has_key?('torrent')
          respond_error(:NotImplemented)
        # Sets acls for the bucket
        elsif params.has_key?('acl')
           @obj = @object
           @acls = @object.acls
           @acls << @object.bucket.acls
           erb :get_access_control_list
        else
          etag @object.etag
          send_file @object.path, :type => @object.content_type, :filename => @object.filename
        end
      end
      
      # Put operations on the bucket
      put '/:bucket/?' do |bucket|
        setup :bucket => bucket
        
        # Sets versioning for the bucket
        if params.has_key?('versioning')
          require_acl :full_control, @bucket
          begin
            @bucket.versioning_from_xml(request.body.read)
          rescue Smoke::Server::S3Exception => e
            respond_error(e.key)
          end
          respond_ok
        # Sets acls for the bucket
        elsif params.has_key?('acl')
          require_acl :write_acl, @bucket
          begin
            Acl.from_xml(request.body, @bucket) do |acl|
              acl.save!
            end
          rescue Smoke::Server::S3Exception => e
            respond_error(e.key)
          end
          respond_ok
        # Returns the payment configuration.  Currently not used.
        elsif params.has_key?('requestPayment')
          respond_error(:NotImplemented)
        # Returns the website configuration for the bucket.  Currently not used.
        elsif params.has_key?('website')
          respond_error(:NotImplemented)
        # Sets the location of the bucket.  Currently not used, but will
        # be used to transfer buckets to and from alternate storage backends
        # and remote sites, including amazon.
        elsif params.has_key?('location')
          respond_error(:NotImplemented)
        # Sets the logging status of the bucket.
        elsif params.has_key?('logging')
          require_acl :full_control, @bucket
          @bucket.logging_from_xml(request.body.read)
          respond_ok
        # Return the notification status of the bucket.  Not implemented.
        elsif params.has_key?('notification')
          respond_error(:NotImplemented)
        else
          @buckets = @user.buckets
          # The default for max-buckets is 1.  The admin needs to adjust
          # this for a case by case exception to keep users from using
          # buckets as folders.
          if @buckets.count >= @user.max_buckets
            respond_error(:TooManyBuckets)
          end
          
          @bucket = SmBucket.find_by_name(bucket)
          if @bucket.nil?
            @bucket = SmBucket.new(:name => bucket, :user_id => @user.id)
            if params.has_key?('x-amz-acl')
              # Sets public visibility.  This is read only, by default this is
              # private.
              @bucket.visibility = params['x-amz-acl']
            end
            @bucket.save
          elsif @bucket.user.id = @user.id
            respond_error(:BucketAlreadyOwnedByYou)
          else
            respond_error(:BucketAlreadyExists)
          end
          respond_ok
        end 
      end
      
      # This may end up being a special case used to create application/x-directory
      # objects.  Assets already handles this in the write method.
      put '/:bucket/*/' do |bucket,asset|
        setup :bucket => bucket
        require_acl :write, @bucket
        
        
        @asset = @bucket.find_or_create_asset_by_key(asset)
        @asset.lock
        @asset.write("", "application/x-directory")
        @asset.unlock
        respond_ok(nil,{:etag => @asset.etag})
      end
      
      # Put operations on objects(assets)
      put '/:bucket/*' do |bucket,asset|
        @user = request.env['smoke.user']
        @bucket = Bucket.find_by_name(bucket)
        respond_error(:NoSuchBucket) if @bucket.nil?
        log_access(:PUT, @user, @bucket)
        
        if params.has_key?('acl')
          @asset = @bucket.assets.find_by_key(asset)
          respond_error(:NoSuchKey) if @asset.nil?
          require_acl :write_acl, @asset
          begin
            Acl.from_xml(request.body, @asset) do |acl|
              acl.save!
            end
          rescue Smoke::Server::S3Exception => e
            respond_error(e.key)
          end
          respond_ok
        else
          require_acl :write_acl, @bucket
          @amz = env['smoke.amz_headers']
          @directive = @amz['x-amz-metadata-directive']
          
          # Preform a copy if copy source is defined
          if !@directive.nil? && @amz['x-amz-copy-source']
            respond_error(:NotImplemented)
            # @asset = @bucket.find_or_create_asset_by_key(@amz['x-amz-copy-source'])
            # @asset.copy(asset)
          # Otherwise upload the new object
          else
            @asset = @bucket.find_or_create_asset_by_key(asset)
            @asset.lock
            @asset.write(request.body, request.content_type)
            @asset.unlock
            if @asset.is_placeholder_directory?
              respond_ok
            else
              respond_ok(nil,{:etag => @asset.etag})
            end
          end
        end   
      end
      
      delete '/:bucket/*' do |bucket,object|
        setup :bucket => bucket, :object => object
        require_acl :write, @object
        @object.lock
        @object.trash
        @object.unlock
        respond_ok
      end
    end
    require_relative 'actions/get_service'
  end
end