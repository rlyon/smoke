require 'smoke/plugins/keys/key'

module Smoke
  module Plugins
    module Keys
      
      module ClassMethods
        def keys
          @keys ||= {}
        end

        def key(*args)
          Key.new(*args).tap do |key|
            keys[key.name] = key
            create_accessors_for(key)
            create_key_in_descendants(*args)
            create_indexes_for(key)
            create_validations_for(key)
          end
        end
      end
      
      def initialize(attrs={})
        @_new = true
        self.attributes = attrs
      end
      
      def attributes=(attrs)
        return if attrs.blank?

        attrs.each_pair do |key, value|
          if respond_to?(:"#{key}=")
            self.send(:"#{key}=", value)
          else
            self[key] = value
          end
        end
      end
      
    end
  end
end
      
      