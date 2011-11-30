require 'sinatra/base'
require 'yaml'
require 'active_record'
require 'typhoeus'
require 'nokogiri'
require 'base64'
require 'openssl'
require 'bcrypt'

require 'pp'

$:.unshift(File.dirname(__FILE__))
require 'support/datetime'
require 'support/hash'
require 'support/string'
require 'support/signature'

require 'helpers/session'

#require 'marcel-aws/s3'

require 'web/xml_model'
require 'web/bucket'

require 'web/app'


VERSION = "0.0.1"
SERVER = "Smoke"
CODENAME = "Camel"