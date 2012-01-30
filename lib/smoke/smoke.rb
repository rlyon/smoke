require 'sinatra/base'
require 'nokogiri'
require 'yaml'
require 'base64'
require 'openssl'
require 'bcrypt'
require 'mongo'

$:.unshift(File.dirname(__FILE__))

module Smoke
  autoload :Connection,       'adapters/mongo'
  autoload :Document,         'document'
  autoload :S3Exception,      'exceptions'
  autoload :User,             'models/user'
  autoload :SmBucket,         'models/smbucket'
  autoload :SmObject,         'models/smobject'
  autoload :Acl,              'models/acl'
  
  module Plugins
    autoload :Keys,           'plugins/keys'
    autoload :Model,          'plugins/model'
    autoload :Permissions,    'plugins/permissions'
    autoload :LocalFileStore, 'plugins/localfilestore'
  end

  module Model
    
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
  
  extend Connection
end

Dir[File.join(File.dirname(__FILE__), 'extensions', '*.rb')].each do |extension|
  require extension
end

VERSION = "0.2.0"
SERVER = "Smoke"
CODENAME = "Mary Jane"