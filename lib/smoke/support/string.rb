class String 
  class << self
    def hex(args = { :length => 24, :case => :upper })
      unless args.include_only?( :length, :case )
        raise "Invalid parameters in random"
      end
      
      h = (((0..args[:length]).map{rand(256).chr}*"").unpack("H*")[0][0,args[:length]])
      
      if args[:case] == :lower
        h.downcase
      else
        h.upcase
      end
    end
    
    def random(args = { :length => 24, :charset => :all })
      unless args.include_only?( :length, :charset )
        raise "Invalid parameters in random"
      end 

      if args[:charset] == :alpha
        chars = ('a'..'z').to_a + ('A'..'Z').to_a
      else
        chars = ('a'..'z').to_a + ('A'..'Z').to_a + ('0'..'9').to_a
      end
      (0...args[:length]).collect { chars[Kernel.rand(chars.length)] }.join  
    end
  end  
end