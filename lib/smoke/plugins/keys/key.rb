module Smoke
  module Plugins
    module Keys
      class Key
        attr_accessor :name, :type, :options, :default_value

        def initialize(*args)
          options = args.extract_options!
          @name, @type = args.shift.to_s, args.shift
          self.options = (options || {}).symbolize_keys
          self.default_value = self.options[:default]
        end
        
        def number?
          type == Integer || type == Float
        end
        
        def time?
          type == Time
        end
        
        def string?
          type == String
        end
        
        def bool?
          type == Boolean
        end
        
        def get(value)
          if value.nil? && !default_value.nil?
            if default_value.respond_to?(:call)
              return default_value.call
            else
              return Marshal.load(Marshal.dump(default_value))
            end
          end
          value
        end
        
        def set(value)
          value
        end
        
      end
    end
  end
end