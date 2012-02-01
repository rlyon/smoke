module Smoke
  module S3
    class App < Sinatra::Base
      
      delete '/:bucket/*' do |bucket,object|
        setup :bucket => bucket, :object => object
        require_acl :write, @object
        @object.lock
        @object.trash
        @object.unlock
        respond_ok
      end
      
    end
  end
end