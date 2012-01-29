require 'simplecov'
SimpleCov.start

require 'rubygems'
require 'bundler'
Bundler.setup(:default, :test)
require 'sinatra'
require 'rspec'
require 'rack/test'
require 'mocha'

RSpec.configure do |config|
  config.mock_with :mocha
end

# set test environment
Sinatra::Base.set :environment, :test
Sinatra::Base.set :run, false
Sinatra::Base.set :raise_errors, true
Sinatra::Base.set :logging, false

SMOKE_CONFIG = YAML::load(File.open('config/settings/smoke.yml'))['test']
require File.dirname(__FILE__) + '/../lib/smoke/smoke'
env = ENV['RACK_ENV'] ? ENV['RACK_ENV'] : "test"
Smoke.database = "smoke_#{env}"
