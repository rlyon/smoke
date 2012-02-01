module Smoke
  module S3
    class App < Sinatra::Base
      
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
      
    end
  end
end