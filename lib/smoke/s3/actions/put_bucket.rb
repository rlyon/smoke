module Smoke
  module S3
    class App < Sinatra::Base
      
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
      
    end
  end
end