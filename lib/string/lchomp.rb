
class String
  
  def lchomp(prefix)
    if self.start_with? prefix
      self[prefix.length..-1]
    else
      self
    end
  end
  
end
