module Smoke
  module Plugin
    
    def attribute_names
      @attributes.keys
    end
    
    def assign_attributes(new_attributes)
      return unless new_attributes    
      attributes = new_attributes.stringify_keys
      attributes.each do |key,value|
        if respond_to?("#{key}=")
          send("#{key}=", value)
        else
          raise "Unknown Attribute (#{key})"
        end
      end
    end
    
  end
end