

if RUBY_VERSION < '2.1.0'
  
  class String
    
    def scrub(replacement = "_")
      if not self.valid_encoding?
        result = ""
        self.chars.each do |c|
          if c.valid_encoding? then result << c
          else result << replacement
          end
        end
        return result
      else
        return self
      end
    end
    
  end
  
end