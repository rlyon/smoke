module Smoke
  module Model
    class Base
      def initialize( attributes = {} )
        @attributes = attributes
        assign_attributes(attributes)
        @base_name = self.to_s.split("::").last.downcase
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
          @collection.save(@document)
        else
          @collection.insert @attributes
        end   
      end
      
      class << self
        def find( attributes = {} )
          @base_name = self.to_s.split("::").last.downcase
          @collection = Smoke.database.collection(@base_name)
          model = self.new
          document = @collection.find_one attributes
          puts document.inspect
        end
      
        def where( attributes = {} )
          @base_name = self.to_s.split("::").last.downcase
          @collection = Smoke.database.collection(@base_name)
          @collection.find(attributes).each do |document|
            puts document.inspect
          end
        end
      end
    end
  end
end