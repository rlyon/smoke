module Smoke
  module Plugins
    module Model

        def initialize( attributes = {} )
          @attributes = attributes
          assign_attributes(attributes)
          @base_name = self.class.to_s.split("::").last.downcase
          @collection = Smoke.database.collection(@base_name)
          @document = nil
        end
        
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
        
        def save
          unless @document.nil?
            puts "UPDATING: in #{Smoke.database.name}.#{@base_name}"
            puts "CONTENT: #{@attributes}"
            @collection.save(@document)
          else
            puts "CREATING: in #{Smoke.database.name}.#{@base_name}"
            puts "CONTENT: #{@attributes}"
            @collection.insert @attributes.stringify_keys
          end   
        end
        
        module ClassMethods
          def find( attributes = {} )
            @base_name = self.to_s.split("::").last.downcase
            @collection = Smoke.database.collection(@base_name)
            document = @collection.find_one attributes
            self.new(document)
          end
        
          def where( attributes = {} )
            models = []
            @base_name = self.to_s.split("::").last.downcase
            @collection = Smoke.database.collection(@base_name)
            @collection.find(attributes).each do |document|
              models << self.new(document)
            end
            models
          end
        end

    end
  end
end