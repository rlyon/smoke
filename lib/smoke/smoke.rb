require 'sinatra/base'
require 'nokogiri'
require 'yaml'
require 'base64'
require 'openssl'
require 'bcrypt'
require 'mongo'

$:.unshift(File.dirname(__FILE__))

module Smoke
  autoload :MongoConnector, 'connector/mongo'
  autoload :User,           'models/user'

  module Model
    autoload :Base,    'models/base'
  end

  module S3
    # Fill me when refactoring is complete
  end

  module Web
    # Fill me when refactoring is complete
  end

  module Dav
    # Fill me when refactoring is complete
  end
  
  extend MongoConnector
end

Dir[File.join(File.dirname(__FILE__), 'extensions', '*.rb')].each do |extension|
  require extension
end

VERSION = "0.2.0"
SERVER = "Smoke"
CODENAME = "Mary Jane"