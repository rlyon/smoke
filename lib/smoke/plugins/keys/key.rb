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

        def ==(other)
          @name == other.name && @type == other.type
        end

        def number?
          type == Integer || type == Float
        end
      end
    end
  end
end