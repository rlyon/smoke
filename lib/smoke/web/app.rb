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
          @date = Time.now.to_web
          @username = session['username']
          auth = Signature.new( session['secret_key'],
            :method => "GET",
            :path => "/",
            :amz_headers => { 'x-amz-date' => [@date] }
          )
          response = Typhoeus::Request.get("http://localhost:9292", 
            :headers => {
              'Authorization' => "AWS #{session['access_id']}:#{auth}",
              'x-amz-date' => @date
            }
          )
          pp response.body
          buckets_hash = Hash.from_xml_string(response.body)
          pp buckets_hash
          if response.code == 200
            @buckets = Bucket.load(response.body)
          else
            @buckets = []
          end
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
        logger.info("LOGIN: attempt for #{params[:identity]} using password '%%%%%%%%%%'")
        response = Typhoeus::Request.post("http://localhost:9292", 
          :params => {:username => params[:username], :password => params[:password]}, 
          :headers => {:accept => "application/xml"}
        )
        
        if response.code == 200
          user = Hash.from_xml_string(response.body)[:user_result]
          session_start!
          session['username'] = user[:username]
          session['email'] = user[:email]
          session['access_id'] = user[:access_id]
          session['secret_key'] = user[:secret_key]
          logger.info("LOGIN: New session opened for #{user[:username]}")
          redirect '/' + user[:username]
        else
          error = Hash.from_xml_string(response.body)[:error]
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