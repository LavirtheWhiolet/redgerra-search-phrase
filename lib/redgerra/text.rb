require 'strscan'

module Redgerra
  
  # Redgerra::Text is the same as String but with slightly different methods
  # set.
  class Text
    
    def initialize(str)
      @str = str
      @encoded = Text.encode(str)
    end
    
    def to_s
      @str
    end
    
    # 
    # Accessible to Redgerra::Text and Redgerra::Sloch only.
    # 
    # Returns +str+ with:
    # - words replaced with regexp "W[01]\h+Y\h+W".
    # - whitespace left as is
    # - other items replaced with regexp "O\h+O"
    # 
    def self.encode(str)
      result = ""
      s = StringScanner.new(self)
      until s.eos?
        (word = (s.scan(/['’][Cc]ause/) or s.scan(/#{word_chars = "[a-zA-Z0-9а-яёА-ЯЁ\\$]+"}([\-.'’]#{word_chars})*\'?/o)) and act do
          is_proper_name_with_dot_flag =
            if word.include? "." then "1" else "0" end
          result << "W#{is_proper_name_with_dot_flag}#{word.downcase.hex_encode)}Y#{word.hex_encode}W"
        end) or
        (ws = s.scan(/[\u0009-\u000D\u0020\u0085\u00A0\u1680\u180E\u2000-\u200A\u2028\u2029\u202F\u205F\u3000]+/) and act do
          result << ws
        end)
        (other = s.getch and act do
          result << "O#{str.hex_encode}O"
        end)
      end
      return result
    end
    
    # 
    # Accessible to Redgerra::Text and Redgerra::Sloch only.
    # 
    # Inversion of Text::encode().
    # 
    def self.decode(str)
      str.gsub(/#{WORD}|#{OTHER}/o) do |match|
        case match[0]
        when "W"
          match[/Y(\h+)W/, 1].hex_decode
        when "O"
          match[1...-1].hex_decode
        end
      end
    end
    
    private
    
    class ::String
      
      # returns this +str+ encoded into regular expression "\h+".
      def hex_encode
        r = ""
        self.each_byte do |byte|
          r << byte.to_s(16)
        end
        r
      end
      
      # Inversion of #hex_encode().
      def hex_decode
        self.scan(/\h\h/).map { |code| code.hex }.pack('C*').force_encoding('utf-8')
      end
      
    end
    
    # calls +f+ and returns true.
    def self.act(&f)
      f.()
      return true
    end
    
  end
  
end
