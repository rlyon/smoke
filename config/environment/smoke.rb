require File.dirname(__FILE__) + '/../../lib/smoke/smoke'
env = ENV['RACK_ENV'] ? ENV['RACK_ENV'] : "development"
Smoke.database = "smoke_#{env}"

#SMOKE_CONFIG = YAML::load(File.open(File.dirname(__FILE__) + '/../settings/server.yml'))[env]