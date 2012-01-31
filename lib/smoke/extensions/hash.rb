class Hash
  def stringify_keys
    inject({}) do |options, (key,value)|
      options[key.to_s] = value
      options
    end
  end
  
  # From rails active_support.  Destructively convert all keys to symbols as long as they respond to to_sym
  def symbolize_keys!
    keys.each do |key|
      self[(key.to_sym rescue key) || key] = delete(key)
    end
    self
  end
  
  # From rails active_support.  Return a new hash with all keys converted to symbols
  def symbolize_keys
    dup.symbolize_keys!
  end
  
  def include_only?(*args)
    self.each do |key,value|
      unless args.include?(key)
        return false
      end
    end
    return true
  end
  
  def include_only(*args)
    self.each do |key,value|
      unless args.include?(key)
        raise "Unknown Argument"
      end
    end
  end
  
  class << self
    # https://gist.github.com/819999
    def from_xml_string(xml)
      begin
        result = Nokogiri::XML(xml)
        return { result.root.name => xml_node_to_hash(result.root)}
      rescue Exception => e
        raise "Invalid xml"
      end
    end

    def xml_node_to_hash(node)
      # If we are at the root of the document, start the hash 
      if node.element?
        result_hash = {}
        if node.attributes != {}
          attributes = {}
          node.attributes.keys.each do |key|
            attributes[node.attributes[key].name] = node.attributes[key].value
          end
        end
        if node.children.size > 0
          node.children.each do |child|
            result = xml_node_to_hash(child)

            if child.name == "text"
              unless child.next_sibling || child.previous_sibling
                return result unless attributes
                result_hash[child.name] = result
              end
            elsif result_hash[child.name]

              if result_hash[child.name].is_a?(Object::Array)
                 result_hash[child.name] << result
              else
                 result_hash[child.name] = [result_hash[child.name]] << result
              end
            else
              result_hash[child.name] = result
            end
          end
          if attributes
             #add code to remove non-data attributes e.g. xml schema, namespace here
             #if there is a collision then node content supersets attributes
             result_hash = attributes.merge(result_hash)
          end
          return result_hash
        else
          return attributes
        end
      else
        return node.content.to_s
      end
    end
  end
end