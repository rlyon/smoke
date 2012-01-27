class Array
  
  # From rails active_support
  def extract_options!
    last.is_a?(::Hash) ? pop : {}
  end
end