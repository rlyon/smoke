module Smoke
  module Server
    class Acl < ActiveRecord::Base
      belongs_to :bucket
      belongs_to :user
      belongs_to :asset
      
      #validates :email, :presence => true
      validates :permission, :presence => true
    end
    
    def acl_for()
    end
  end
end