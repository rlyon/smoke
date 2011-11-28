module Smoke
  module Server
    class App < Sinatra::Base
      helpers Sinatra::ResponseHelper
      
      set :views, [File.dirname(__FILE__) + '/../../../views']
      
      # Get service
      get '/' do
        if params.has_key?('user')
          # show user details if user is admin or self
          respond_error(:NotImplemented)
        elsif params.has_key?('auth')
          # show user details if user is admin or self
          respond_error(:NotImplemented)
        elsif params.has_key?('users')
          # show all user details if user is admin
          respond_error(:NotImplemented)
        else
          @user = request.env['smoke.user']
          @buckets = @user.all_my_buckets
          respond_ok(:get_service)
        end
      end
      
      # Put service
      put '/' do
        if params.has_key?('user')
          # update user details if user is admin or self, create if admin
          respond_error(:NotImplemented)
        # The only puts you can do on the service is updating/adding a user
        else
          respond_error(:InvalidRequest)
        end
      end
      
      # Get operations on the bucket
      get '/:bucket/?' do |bucket|
        @user = request.env['smoke.user']
        @bucket = Bucket.find_by_name(bucket)
        
        respond_error(:NoSuchBucket) if @bucket.nil?
        respond_error(:AccessDenied) unless @bucket.permissions(@user).include? :read
        log_access(:GET, @user, @bucket)
        
        if params.has_key?('versioning')
          erb :get_bucket_versioning
          
        elsif params.has_key?('acl')
          @acls = @bucket.acls
          erb :get_bucket_acl
          
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
            @assets = @bucket.assets
            @common_prefixes = []
          else
            @assets = @bucket.find_filtered_assets :prefix => @prefix, :max_keys => @max_keys
            @common_prefixes = @bucket.common_prefixes :prefix => @prefix, :delimiter => params['delimiter']
          end
          
          erb :get_bucket
        end
      end
      
      # Get operations on the object (asset)
      get '/:bucket/*' do |bucket,asset|
        @user = request.env['smoke.user']
        @bucket = Bucket.find_by_name(bucket)
        
        respond_error(:NoSuchBucket) if @bucket.nil?
        respond_error(:AccessDenied) unless @bucket.permissions(@user).include? :read
        log_access(:GET, @user, @bucket)
        
        @asset = @bucket.assets.where(:key => asset).first
        respond_error(:NoSuchKey) if @asset.nil?
        
        if params.has_key?('torrent')
          respond_error(:NotImplemented)
        # Sets acls for the bucket
        elsif params.has_key?('acl')
          respond_error(:NotImplemented)
        else
          respond_error(:AccessDenied) unless @asset.permissions(@user).include? :read
          etag @asset.etag
          send_file @asset.path, :type => @asset.content_type, :filename => @asset.filename
        end
      end
      
      # Put operations on the bucket
      put '/:bucket/' do |bucket|
        bucket_already_exists = false
        @user = request.env['smoke.user']
        
        # Sets versioning for the bucket
        if params.has_key?('versioning')
          respond_error(:NotImplemented)
        # Sets acls for the bucket
        elsif params.has_key?('acl')
          @bucket = Bucket.find_by_name(bucket)
          unless @bucket.permissions(@user).include? :write_acl
            error = Error.new(request.env, :AccessDenied)
            response = error.respond
            halt response['status'], response['header'], response['body']
          end
          
          parser = XmlParser.new(request.body)
          grants = parser.parse_grants
          unless grants.nil?
            grants.each do |key,permissions|
              @bucket.remove_acls(key)
              @bucket.add_acls(key,permissions)
            end
            respond_ok
          else
            response = Error.new(request.env, parser.errors.first[:key]).respond
            halt response['status'], response['header'], response['body']
          end
          
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
          @bucket = Bucket.find_by_name(bucket)
          respond_error(:AccessDenied) unless @bucket.permissions(@user).include? :full_control
          @bucket.is_logging = true
          @bucket.save
          respond_ok(request.env, :get_bucket_logging)    
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
          
          @bucket = Bucket.find_by_name(bucket)
          if @bucket.nil?
            @bucket = @user.buckets.new(:name => bucket)
            if params.has_key('x-amz-acl')
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
      
      # Put operations on objects(assets)
      put '/:bucket/*' do |bucket,asset|
        @user = request.env['smoke.user']
        @bucket = Bucket.find_by_name(bucket)
        
        respond_error(:NoSuchBucket) if @bucket.nil?
        log_access(:PUT, @user, @bucket)
        
        if params.has_key?('acl')
          respond_error(:NotImplemented)
        else
          respond_error(:AccessDenied) unless @bucket.permissions(@user).include? :write
          @asset = @bucket.assets.where(:key => asset).first
          @asset ||= @bucket.assets.new(:key => asset, :user_id => @user.id)
          @asset.lock
          @asset.write(request.body, request.content_type)
          @asset.unlock
          respond_ok(nil,{:etag => @asset.etag})
        end
          
      end
    end
  end
end