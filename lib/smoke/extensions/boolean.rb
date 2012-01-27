module Smoke
  module Extensions
    module Boolean
      Mapping = {
        true    => true,
        'true'  => true,
        '1'     => true, 
        1       => true, 
        false   => false, 
        'false' => false,
        '0'     => false,
        0       => false, 
        nil     => nil
      }

      def to_mongo(value)
        if value.is_a?(Boolean)
          value
        else
          Mapping[value]
        end
      end

      def from_mongo(value)
        value.nil? ? nil : !!value
      end
    end
  end
end

class Boolean; end unless defined?(Boolean)
Boolean.extend Smoke::Extensions::Boolean