require 'sinatra/base'
require 'yaml'
require 'active_record'

$:.unshift(File.dirname(__FILE__))
require 'support/datetime'
require 'support/hash'
require 'support/string'

require 'helpers/session'

require 'marcel-aws/s3'

require 'web/app.rb'


VERSION = "0.0.1"
SERVER = "Smoke"
CODENAME = "Camel"