module Smoke
  module S3
    class App < Sinatra::Base
      helpers Sinatra::ResponseHelper
      helpers Sinatra::FetchHelper
      
      set :views, [File.dirname(__FILE__) + '/views']
      
      # Put service to update user attributes or create a user if that user does
      # not already exist.  Users will have the ability to update their own profiles 
      # and attributes and administrators will have the ability to create new users
      # and modify other users. 
      #put '/' do
      #  if params.has_key?('user')
      #    # update user details if user is admin or self, create if admin
      #    respond_error(:NotImplemented)
      #  # The only puts you can do on the service is updating/adding a user
      #  else
      #    respond_error(:InvalidRequest)
      #  end
      #end
      
      # Initial authentication service used for administrative services, user updating
      # and creation.  Basically, this post allows an external interface to authenticate
      # via [username/email] and a standard password and returns the access ID and 
      # key back so all requests can include the standard auth headers
      #post '/' do
      #  @user = User.authenticate(params[:username],params[:password])
      #  if @user
      #    erb :user
      #  else
      #    respond_error(:AccessDenied)
      #  end
      #end
      
    end
    require_relative 'actions/get_service'
    require_relative 'actions/get_bucket'
    require_relative 'actions/get_object'
    require_relative 'actions/head_object'
    require_relative 'actions/put_bucket'
    require_relative 'actions/put_object'
    require_relative 'actions/delete_bucket'
    require_relative 'actions/delete_object'
    
  end
end