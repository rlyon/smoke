module Smoke
  module S3
    class App < Sinatra::Base
    
      # Get service.  Implements the standard S3 Get Service command and is
      # extended to handle listing user(s) attributes for external interfaces.
      # This will be also be used for a directory style lookup to search for users
      # to share with.
      get '/' do
        setup
        
        if params.has_key?('user')
          # show user details if user is admin or self
          respond_error(:NotImplemented)
        elsif params.has_key?('users')
          # show all user details if user is admin or has allowed directory lookup
          respond_error(:NotImplemented)
        else
          respond_ok(:get_service)
        end
      end
      
    end
  end
end