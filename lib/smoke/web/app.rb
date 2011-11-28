module Smoke
  module Web
    class App < Sinatra::Base
      register Sinatra::Session
      
      set :session_fail, '/login'
      set :session_secret, 'afiefnaioasdfjhkdku47f34jafusduf47fasdfe'
      set :views, [File.dirname(__FILE__) + '/views']
      set :logs, [File.dirname(__FILE__) + '/../../../../logs']
      
      configure :development do
        
      end
      
      get '/' do
        if session?
          @username = session[:username]
          erb :dashboard
        else
      	  erb :index
    	  end
      end
      
      # Login to the account
      get '/login' do
        if session?
          redirect '/'
        else
          erb :login
        end
      end
      
      post '/login' do
        if params[:username] == "mocky" && params[:password] == "1rcmocky"
          logger.info("LOGIN: attempt for #{params[:username]} using password '%%%%%%%%%%'")
          session_start!
          session['username'] = params[:username]
          session['access_key'] = '0PN5J17HBGZHT7JJ3X82'
          session['secret_key'] = 'uV3F3YluFJax1cknvbcGwgjvx4QpvB+leU8dUj2o'
          logger.info("LOGIN: New session opened for #{session['username']}")
          redirect '/' + 'mocky'
        else
          redirect '/login'
        end
      end
      
      get '/logout' do
        session_end!
        redirect '/'
      end

      get '/account' do
      	"My Account"
      end

      get '/admin' do
      	"Administration"
      end

      get '/:user/?' do |user|
        @user = 
      	"Hello #{user} listing your buckets"
      end

      get '/:user/:bucket' do |user,bucket|
      	"Hello #{user} showing files in: #{bucket}"
      end

      get '/:user/:bucket/*' do |user,bucket,file|
      	"Hello #{user} accessing file: #{file} in #{bucket}"
      end
    end
  end
end