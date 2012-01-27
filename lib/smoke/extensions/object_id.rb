module Smoke
  module Extensions
    module ObjectId
      
    end
  end
end

class ObjectId; end unless defined?(ObjectId)
ObjectId.extend Smoke::Extensions::ObjectId