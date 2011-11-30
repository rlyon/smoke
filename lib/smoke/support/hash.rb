class Hash
  def stringify_keys
    inject({}) do |options, (key,value)|
      options[key.to_s] = value
      options
    end
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
    def from_xml_string(xml)
      doc = Nokogiri::XML(xml)
      {doc.root.name.uncamelize.to_sym => xml_node_to_hash(doc.root)}
    end
    
    def xml_node_to_hash(node)
      return to_value(node.content.to_s) unless node.element?
      
      result_hash = {}
      
      node.children.each do |child|
        result = xml_node_to_hash(child)
        if child.name == "text"
          return to_value(result) unless child.next_sibling || child.previous_sibling
        else
          key,value = child.name.uncamelize.to_sym, to_value(result)
          result_hash[key] = result_hash.key?(key) ? Array(result_hash[key]).push(value) : value
        end
      end
      result_hash
    end
    
    def to_value(data)
      data.is_a?(String) && data =~ /^\d+$/ ? data.to_i : data
    end
  end
end