module Smoke
  module S3
    class App < Sinatra::Base
      
      delete '/:bucket/?' do |bucket|
        setup :bucket => bucket
        respond_error(:NotImplemented)
      end
      
    end
  end
end