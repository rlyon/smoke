class DateTime
  def to_z
    self.gmtime.strftime("%Y-%m-%dT%H:%M:%S.000Z")
  end
end

class Time
  def to_z
    self.gmtime.strftime("%Y-%m-%dT%H:%M:%S.000Z")
  end
  
  def to_yearmonth
    self.gmtime.strftime("%Y%m")
  end
  
end