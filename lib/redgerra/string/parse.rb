
module Redgerra
  
  class ::String
    
    # 
    # Passes +block+ with:
    # - (word, :word) - if it encounters a word.
    # - (other, :other) - if it encounters a character.
    # 
    # Returns this String with all parts replaced with results of +block+.
    # 
    def parse(&block)
      result = ""
      s = StringScanner.new(self)
      until s.eos?
        (word = (s.scan(/['’][Cc]ause/) or s.scan(/#{word_chars = "[a-zA-Z0-9\\$]+"}([\-.'’]#{word_chars})*\'?/o)) and act do
          result << block.(word, :word)
        end) or
        (other = s.getch and act do
          result << block.(other, :other)
        end)
      end
      return result
    end
    
    private
    
    # calls +f+ and returns true.
    def act(&f)
      f.()
      return true
    end
    
  end
  
end
