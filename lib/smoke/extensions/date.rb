class Date
  
  # From active support
  def advance(options)
    options = options.dup
    d = self
    d = d >> options.delete(:years) * 12 if options[:years]
    d = d >> options.delete(:months)     if options[:months]
    d = d +  options.delete(:weeks) * 7  if options[:weeks]
    d = d +  options.delete(:days)       if options[:days]
    d
  end
  
  # From active support
  def change(options)
    ::Date.new(
      options[:year]  || self.year,
      options[:month] || self.month,
      options[:day]   || self.day
    )
  end
end