require 'simplecov'
SimpleCov.start

require 'rubygems'
require 'bundler'
Bundler.setup(:default, :test)
require 'sinatra'
require 'rspec'
require 'rack/test'
require 'active_record'
require 'mocha'

RSpec.configure do |config|
  config.mock_with :mocha
end

# set test environment
Sinatra::Base.set :environment, :test
Sinatra::Base.set :run, false
Sinatra::Base.set :raise_errors, true
Sinatra::Base.set :logging, false

SMOKE_CONFIG = YAML::load(File.open('config/settings/server.yml'))['test']
ActiveRecord::Base.establish_connection(YAML::load(File.open('config/database.yml'))['test'])

require File.join(File.dirname(__FILE__), '/../../lib/smoke/', 'server.rb')
