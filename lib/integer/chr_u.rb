
class Integer
  
  # Unicode version of Integer#chr.
  def chr_u
    [self].pack("U")
  end
  
end