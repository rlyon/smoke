module Smoke
  module Server
    class Version < ActiveRecord::Base
      belongs_to :asset
    end
  end
end