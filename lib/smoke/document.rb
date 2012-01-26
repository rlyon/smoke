module Smoke
  module Document
    include Plugin::Attributes
    
    def save
      unless @document.nil?
        database.collection.save(@document)
      else
        puts @attributes.stringify_keys.inspect
        database.collection.insert @attributes.stringify_keys
      end   
    end
    
  end
end