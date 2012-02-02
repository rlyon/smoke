module Smoke
  module S3
    class App < Sinatra::Base
      
      # Put operations on objects(assets)
      put '/:bucket/*/?' do |bucket,asset|
        setup :bucket => bucket
        
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
          require_acl :write, @bucket
          
          # Preform a copy if copy source is defined
          if @amz_directive && @amz['x-amz-copy-source']
            respond_error(:NotImplemented)
            # @asset = @bucket.find_or_create_asset_by_key(@amz['x-amz-copy-source'])
            # @asset.copy(asset)
          # Otherwise upload the new object
          else
            @asset = SmObject.find_or_create(@user, @bucket, asset)
            @asset.content_type = request.content_type
            @asset.save
            
            @asset.lock
            @asset.store(request.body)
            @asset.unlock
            
            if @asset.is_placeholder?
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