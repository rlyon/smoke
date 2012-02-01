module Smoke
  module S3
    class App < Sinatra::Base
    
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
    
    end
  end
end