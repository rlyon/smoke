module Smoke
  module Plugins
    module Model

        def save
          # check attributes for response
          Smoke.collection(self.base_name).save(attributes)
        end
        
        def base_name
          @base_name ||= self.class.to_s.split("::").last.downcase
        end
        
        module ClassMethods
          # There has got to be a better way!!!!
          def base_name
            @base_name ||= self.to_s.split("::").last.downcase
          end
          
          def find( attrs = {} )
            document = Smoke.collection(base_name).find_one attrs
            unless document.nil?
              self.new(document)
            else
              nil
            end
          end
          
          def remove( attrs = {} )
            unless attrs && attrs.include?(:force) && !attrs[:force]
              raise S3Exception.new(:InternalError, "[Model.remove]: Will not comply with empty attributes without force")
            end
            Smoke.collection(base_name).remove(attrs)
          end
        
          def where( attrs = {} )
            models = []
            Smoke.collection(base_name).find(attrs).each do |document|
              models << self.new(document)
            end
            models
          end
        end

    end
  end
end