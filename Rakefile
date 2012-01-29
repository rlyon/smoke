#require "bundler/gem_tasks"
require 'rspec/core/rake_task'
require 'yard'
require File.dirname(__FILE__) + '/lib/smoke/smoke'

def library_root
  File.dirname(__FILE__)
end

task :default => :spec

desc 'Generate Yard documentation'
YARD::Rake::YardocTask.new do |t|
  t.files   = ['lib/smoke/*.rb', 'lib/smoke/**/*.rb']
  t.options = ['--private', '--protected']
end

desc 'Generate Graphviz object graph'
task :garden => :yard do
  sh 'yard graph --full --dependencies --dot="-Tpng:quartz" -f doc/images/smoke.dot'
  sh 'dot -Tpng doc/images/smoke.dot -o doc/images/smoke.png'
end

desc "Run all specs"
RSpec::Core::RakeTask.new(:spec) do |t|
  t.rspec_opts = %w{--colour --format progress}
  t.pattern = 'spec/*_spec.rb'
end

task :showcov do
  system("open #{File.join(library_root, 'coverage/index.html')}")
end

task :environment do
  env = ENV['RACK_ENV'] ? ENV['RACK_ENV'] : "development"
  SMOKE_CONFIG = YAML::load(File.open('config/settings/smoke.yml'))[env]
end
