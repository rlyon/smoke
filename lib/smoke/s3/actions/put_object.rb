module Smoke
  module S3
    class App < Sinatra::Base
    
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
      
    end
  end
end