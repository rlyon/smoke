require 'sinatra/base'
module Sinatra
  module Session
    module Helpers
      def session_start!
        session['sinatra.session'] = true
        session['sinatra.flash'] = {}
      end
      
      def session_end!
        session.clear
      end
      
      def session?
        !! session['sinatra.session']
      end
      
      def session!
        redirect(settings.session_fail) unless session? || settings.session_fail == request.path_info
      end
      
      def session_messages()
        return session['sinatra.flash']
      end
      
      def session_notice(message)
        session['sinatra.flash']['notice'] = message
      end
      
      def session_warning(message)
        session['sinatra.flash']['warning'] = message
      end
      
      def session_error(message)
        session['sinatra.flash']['error'] = message
      end
    end
      
    module Cookie
      def self.new(app, options={})
        options.merge!(yield) if block_given?
        Rack::Session::Cookie.new(app,options)
      end
    end
    
    def self.registered(app)
      app.helpers Session::Helpers
      app.set :session_fail, '/login'
      app.set :session_name, 'sinatra.session'
      app.set :session_path, '/'
      app.set :session_domain, nil
      app.set :session_expire, nil
      app.set :session_secret, nil
      
      app.use(Session::Cookie) do
        { :key          => app.session_name,
          :path         => app.session_path,
          :domain       => app.session_domain,
          :expire_after => app.session_expire,
          :secret       => app.session_secret
        }
      end
    end
  end
  
  register Session
end