require 'plugins/keys/key'

module Smoke
  module Plugins
    module Keys
      
      module ClassMethods
        
        def create_accessors(key)
          define_method("#{key.name}") do
            read_key(":#{key.name}")
          end

          define_method("#{key.name}=(value)") do
            write_key(":#{key.name}", value)
          end

          define_method("#{key.name}?") do
            !read_key(":#{key.name}").empty?
          end
        end  
          
        def keys
          @keys ||= {}
        end

        def key(*args)
          Key.new(*args).tap do |key|
            keys[key.name] = key
            create_accessors(key)
          end
        end
        
      end
      
      ####################################################
      def initialize(attrs={})
        @_new = true
        self.attributes = attrs
      end
      
      def attributes=(attrs)
        return if attrs.empty?

        attrs.each_pair do |key, value|
          if respond_to?(:"#{key}=")
            self.send(:"#{key}=", value)
          else
            self[key] = value
          end
        end
      end
      
      def attributes
        keys.select { |name,key| !self[key.name].nil? || key.type == ObjectId }.each do |name, key|
          value = key.set(self[key.name])
          attrs[name] = value
        end
      end
      
      def id
        _id
      end
      
      def id=(value)
        self[:_id] = value
      end
      
      def keys
        self.class.keys
      end
      
      def key_names
        keys.keys
      end

      def [](name)
        read_key(name)
      end
      
      def []=(name,value)
        raise "No key dumbass!!!" unless has_key?(name)
        write_key(name,value)
      end
      
      def has_key?(name)
        self.class.key(name) unless respond_to?("#{name}=")
      end
      
      private
        def read_key(name)
          if key = keys[name.to_s]
            value = key.get(instance_variable_get(:"@#{name}"))
            instance_variable_set(:"@#{name}", value)
          end
        end
        
        def write_key(name, value)
          key = keys[name.to_s]
          instance_variable_set(:"@#{name}", key.set(value))
        end
        
    end
  end
end
      
      