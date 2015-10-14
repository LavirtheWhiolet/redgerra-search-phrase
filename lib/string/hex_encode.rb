
class String

  # returns this String encoded into regular expression "\h+".
  def hex_encode
    r = ""
    self.each_byte do |byte|
      r << byte.to_s(16)
    end
    r
  end
  
end