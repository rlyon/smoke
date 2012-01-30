module Smoke
  class Version
    include Smoke::Document
    include Smoke::Plugins::LocalFileStore
    
    key :object_id, String
    key :version_string, String, :default => String.random(:length => 24)
    key :etag, String
    key :size, Integer, :default => 0
    key :content_type, :string => 'application/octet-stream'
    
    def object
      # how do we cache and still update after the move?
      @object_cache ||= SmObject.find(:_id => self.object_id)
    end
    
    def path
      "#{self.object.dirname}/.#{self.object.basename}.#{self.version_string}"
    end

  end
end