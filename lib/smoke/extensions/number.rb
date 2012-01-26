class Fixnum
  def days
    Time.now + (60 * 60 * 24 * self)
  end
  
  def hours
    Time.now + (60 * 60 * self)
  end
  
  def weeks
    Time.now + (60 * 60 * 24 * 7 * self)
  end
  
  def months
    Time.now.advance(:months => self)
  end
  
  def years
    Time.now.advance(:years => self)
  end
end