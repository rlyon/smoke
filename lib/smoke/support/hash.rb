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
end