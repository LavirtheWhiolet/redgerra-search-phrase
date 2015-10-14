
class String
  
  # Inversion of #hex_encode().
  def hex_decode
    self.scan(/\h\h/).map { |code| code.hex }.pack('C*').force_encoding('utf-8')
  end
  
end