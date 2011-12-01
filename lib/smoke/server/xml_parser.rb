module Smoke
  module Server
    class XmlParser
      attr_reader :errors, :xml
      
      def initialize(xml)
        @errors = []
        @xml = xml
      end

      def contains_text?(tag, value)
        body = Nokogiri::XML(@xml)
        body.search(tag).each do |element|
          return true if element.text == value
        end
        return false
      end

    end
  end
end