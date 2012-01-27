module Smoke
  module Plugins
    module Model

        def save
          Smoke.collection(@base_name).save(attributes)
        end
        
        module ClassMethods
          def base_name(name)
            @base_name = name
          end
          
          def find( attrs = {} )
            document = Smoke.collection(@base_name).find_one attrs
            unless document.nil?
              self.new(document)
            else
              nil
            end
          end
        
          def where( attrs = {} )
            models = []
            Smoke.collection(@base_name).find(attrs).each do |document|
              models << self.new(document)
            end
            models
          end
        end

    end
  end
end