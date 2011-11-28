require File.dirname(__FILE__) + '/../../lib/smoke/server'
env = ENV['SMOKE_ENV'] ? ENV['SMOKE_ENV'] : "development"
ActiveRecord::Base.establish_connection(YAML::load(File.open(File.dirname(__FILE__) + '/../database.yml'))[env])
SMOKE_CONFIG = YAML::load(File.open(File.dirname(__FILE__) + '/../settings/server.yml'))[env]