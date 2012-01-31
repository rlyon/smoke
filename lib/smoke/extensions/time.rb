class Time
  def to_z
    self.gmtime.strftime("%Y-%m-%dT%H:%M:%S.000Z")
  end
  
  def to_web
    self.gmtime.strftime("%a, %d %b %Y %H:%M:%S %z")
  end
  
  def to_yearmonth
    self.gmtime.strftime("%Y%m")
  end
  
  # From active support
  def advance(options)
    unless options[:weeks].nil?
      options[:weeks], partial_weeks = options[:weeks].divmod(1)
      options[:days] = (options[:days] || 0) + 7 * partial_weeks
    end
  
    unless options[:days].nil?
      options[:days], partial_days = options[:days].divmod(1)
      options[:hours] = (options[:hours] || 0) + 24 * partial_days
    end
  
    d = to_date.advance(options)
    time_advanced_by_date = change(:year => d.year, :month => d.month, :day => d.day)
    seconds_to_advance = (options[:seconds] || 0) + (options[:minutes] || 0) * 60 + (options[:hours] || 0) * 3600
    seconds_to_advance == 0 ? time_advanced_by_date : time_advanced_by_date.since(seconds_to_advance)
  end
  
  # From active support
  def change(options)
    ::Time.send(
      utc? ? :utc_time : :local_time,
      options[:year]  || year,
      options[:month] || month,
      options[:day]   || day,
      options[:hour]  || hour,
      options[:min]   || (options[:hour] ? 0 : min),
      options[:sec]   || ((options[:hour] || options[:min]) ? 0 : sec),
      options[:usec]  || ((options[:hour] || options[:min] || options[:sec]) ? 0 : usec)
    )
  end
  
  class << self
    # From active support
    # Wraps class method +time_with_datetime_fallback+ with +utc_or_local+ set to <tt>:utc</tt>.
    def utc_time(*args)
      time_with_datetime_fallback(:utc, *args)
    end
  
    # From active support
    # Wraps class method +time_with_datetime_fallback+ with +utc_or_local+ set to <tt>:local</tt>.
    def local_time(*args)
      time_with_datetime_fallback(:local, *args)
    end
    
    # From active support
    # Returns a new Time if requested year can be accommodated by Ruby's Time class
    # (i.e., if year is within either 1970..2038 or 1902..2038, depending on system architecture);
    # otherwise returns a DateTime.
    def time_with_datetime_fallback(utc_or_local, year, month=1, day=1, hour=0, min=0, sec=0, usec=0)
      time = ::Time.send(utc_or_local, year, month, day, hour, min, sec, usec)
      # This check is needed because Time.utc(y) returns a time object in the 2000s for 0 <= y <= 138.
      time.year == year ? time : ::DateTime.civil_from_format(utc_or_local, year, month, day, hour, min, sec)
    rescue
      ::DateTime.civil_from_format(utc_or_local, year, month, day, hour, min, sec)
    end
  end
end