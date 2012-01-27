module Smoke
  module Document
    include Smoke::Plugins::Model
    include Smoke::Plugins::Keys
    
    def self.included(klass)
      klass.extend(Smoke::Plugins::Model::ClassMethods)
      klass.extend(Smoke::Plugins::Keys::ClassMethods)
      klass.key :_id, ObjectId, :default => lambda { BSON::ObjectId.new }
    end
        
  end
end