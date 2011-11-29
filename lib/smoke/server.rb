require 'sinatra/base'
require 'nokogiri'
require 'yaml'
require 'active_record'
require 'base64'
require 'openssl'
require 'bcrypt'

$:.unshift(File.dirname(__FILE__))
require 'support/datetime'
require 'support/hash'
require 'support/string'
require 'support/signature'

require 'helpers/response'

require 'server/acl'
require 'server/asset'
require 'server/auth'
require 'server/bucket'
require 'server/user'
require 'server/version'
require 'server/xml_parser'

require 'server/app'

VERSION = "0.0.1"
SERVER = "Smoke"
CODENAME = "Mary Jane"

