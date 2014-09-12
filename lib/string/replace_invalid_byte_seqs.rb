
class String
  
  def replace_invalid_byte_seqs(replacement = "_")
    if not self.valid_encoding?
      result = ""
      self.chars.each do |c|
        if c.valid_encoding? then result << c
        else result << replacement
        end
      end
      return result
    end
  end
  
end
