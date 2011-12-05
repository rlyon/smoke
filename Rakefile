#require "bundler/gem_tasks"
require 'rspec/core/rake_task'
require 'active_record'
require 'yard'
require File.dirname(__FILE__) + '/lib/smoke/server'

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
  t.pattern = 'spec/server/*_spec.rb'
end

task :showcov do
  system("open #{File.join(library_root, 'coverage/index.html')}")
end

namespace :db do
  desc "Create the databases."
  task :create => :environment do
    ActiveRecord::Schema.define do
      create_table :users do |table|
        table.column :username, :string, :default => nil
        table.column :access_id, :string, :default => nil
        table.column :secret_key, :string, :default => nil
        table.column :display_name, :string, :default => nil
        table.column :email, :string, :default => nil
        table.column :max_buckets, :integer, :default => 1
        table.column :expires_at, :datetime, :default => Time.now
        table.column :is_active, :boolean, :default => SMOKE_CONFIG['auto_activate']
        table.column :role, :string, :default => "standard"
        table.column :enc_password, :string, :default => nil
        table.timestamps
      end
      create_table :buckets do |table|
        table.column :name, :string, :default => nil
        table.column :is_logging, :boolean, :default => false    
        table.column :is_versioning, :boolean, :default => false   # nil => never, true => enabled, false => suspended
        table.column :is_notifying, :boolean, :default => false
        table.column :storage, :string, :default => "local"        # :local or :remote 
        table.column :location, :string, :default => nil           # path or ip address
        table.column :user_id, :integer, :default => nil
        table.column :visibility, :string, :default => "private"
        table.timestamps
      end
      
      create_table :notifiers do |table|
        table.column :topic, :string, :default => nil
        table.column :event, :string, :default => nil
        table.column :bucket_id, :integer, :default => nil
        table.timestamps
      end
      
      create_table :assets do |table| # Really objects but I don't want any conflicts
        table.column :key, :string, :default => nil
        table.column :size, :integer, :default => 0
        table.column :storage_class, :string, :default => "standard"
        table.column :etag, :string, :default => nil      # The md5sum
        table.column :user_id, :integer, :default => nil
        table.column :bucket_id, :integer, :default => nil
        table.column :content_type, :string, :default => "application/octet-stream"
        table.column :locked, :boolean, :default => false
        table.column :delete_marker, :boolean, :default => false
        table.column :delete_at, :datetime, :default => nil
        table.timestamps
      end
      
      create_table :versions do |table|
        table.column :asset_id, :integer, :default => nil
        table.column :version_string, :string, :default => nil
        table.column :size, :integer, :default => 0
        table.column :etag, :string, :default => nil      # The md5sum
        table.column :content_type, :string, :default => "text/plain"
        table.column :locked, :boolean, :default => false
        table.timestamps
      end
      
      create_table :acls do |table|
        table.column :user_id, :integer, :default => nil
        table.column :bucket_id, :integer, :default => nil
        table.column :asset_id, :integer, :default => nil
        table.column :permission, :string, :default => "read"
        table.timestamps
      end
      
      add_index :buckets, :user_id
      add_index :notifiers, :bucket_id
      add_index :assets, :user_id
      add_index :assets, :bucket_id
      add_index :acls, :user_id
      add_index :acls, :bucket_id
      add_index :acls, :asset_id
      add_index :versions, :asset_id
    end
  end
  
  desc "Seed databases"
  task :seed => :environment do
    # Once devel is done these need to auto load admin user.
    first_user = Smoke::Server::User.new(  :access_id => "0PN5J17HBGZHT7JJ3X82", 
                            :expires_at => Time.now.to_i + (60*60*24*28), 
                            :secret_key => "uV3F3YluFJax1cknvbcGwgjvx4QpvB+leU8dUj2o",
                            :username => "mocky",
                            :password => "mysecretpassword",
                            :display_name => "Mocky User",
                            :email => "mocky@dev.null.com",
                            :role => "admin")
    
    first_user.save!
    second_user = Smoke::Server::User.new( :access_id => "0PN5J17HBGZHT7JJ3X83", 
                            :expires_at => Time.now.to_i + (60*60*24*28), 
                            :secret_key => "uV3F3YluFJax1cknvbcGwgjvx4QpvB+leU8dUj2p",
                            :username => "bocky",
                            :password => "mysecretpassword",
                            :display_name => "Bocky User",
                            :email => "bocky@dev.null.com")
    second_user.save!
  end
  
  desc "Drop all the tables."
  task :drop => :environment do
    ActiveRecord::Schema.define do
      drop_table :users
      drop_table :buckets
      drop_table :assets
      drop_table :acls
      drop_table :notifiers
      drop_table :versions
    end
  end
end

task :environment do
  env = ENV['SMOKE_ENV'] ? ENV['SMOKE_ENV'] : "development"
  SMOKE_CONFIG = YAML::load(File.open('config/settings/server.yml'))[env]
  ActiveRecord::Base.establish_connection(YAML::load(File.open('config/database.yml'))[env])
end
