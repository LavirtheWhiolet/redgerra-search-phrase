
class String
  
  def replace_invalid_byte_seqs(replacement = "_")
    result = ""
    self.chars.each do |c|
      if c.valid_encoding? then result << c
      else result << replacement
      end
    end
    return result
  end
  
end
