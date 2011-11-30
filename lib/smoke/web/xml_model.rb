module Smoke
  module Web
    class XMLModel
      attr_reader :attributes
      
      def initialize( attributes = {} )
        @attributes = attributes
        assign_attributes(attributes)
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
      
      class << self
        def load(xml)
          id = self.to_s.split('::').last
          doc = Nokogiri::XML(xml)

          results = []
          doc.search(id).each do |element|
            tags = {}
            element.children.each do |child|
              tags[child.name.uncamelize.to_sym] = child.text if child.element?
            end
            results << self.new(tags) 
          end
          pp results
          results
        end
      end
    end
  end
end
