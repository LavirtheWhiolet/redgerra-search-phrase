  class Text
    
    class << self
      
      # Private.
      alias __original_new__ new
      
      # 
      # +str+ must be String#squeeze_unicode_whitespace()-ed.
      # 
      def new(str)
        __original_new__(str, nil)
      end
      
      def from_encoded_string(encoded_string)
        __original_new__(nil, encoded_string)
      end
    
    end
    
    def to_s
      @str ||= begin
        @encoded_str.gsub(/#{Word::ENCODED_REGEXP}/o) do |encoded_word|
          Word.from_encoded_string(encoded_word).to_s
        end
      end
    end
    
    def to_encoded_string
      @encoded_str ||= begin
        result = ""
        s = StringScanner.new(@str)
        until s.eos?
          (slang = s.scan(/\'[Cc]ause/) and act do
            result << Word.new(slang).to_encoded_string
          end)
          (word = s.scan(/#{word_chars = "[a-zA-Z0-9\\$]+"}([\-\.\']#{word_chars})*\'?/o) and act do
            is_proper_name_with_dot = word.include?(".")
            result << Word.new(word, is_proper_name_with_dot).to_encoded_string
          end) or
          (other = s.getch and act do
            result << other
          end)
        end
        result
      end
    end
    
    def inspect
      "#<Text #{to_s.inspect}>"
    end
    
    def include?(sloch)
      sloch.to_encoded_regexp === self.to_encoded_string
    end
    
    def phrases
      punctuation_and_whitespace = "[\\,\\ ]"
      self.to_encoded_string.scan(/((#{Word::ENCODED_REGEXP}|#{punctuation_and_whitespace})+[\!\?\.\;…]*)/o).map(&:first).
        map do |encoded_phrase|
          encoded_phrase.gsub(/^#{punctuation_and_whitespace}*|#{punctuation_and_whitespace}*$/o, "")
        end.
        reject(&:empty?).
        map { |encoded_phrase| Text.from_encoded_string(encoded_phrase) }
    end
    
    def words
      self.to_encoded_string.scan(/#{Word::ENCODED_REGEXP}/o).map do |encoded_word|
        Word.from_encoded_string(encoded_word)
      end
    end
    
    def words_count
      self.to_encoded_string.scan(/#{Word::ENCODED_REGEXP}/o).size
    end
    
    def upcase?
      /[a-z]/ !~ self.to_s
    end
    
    def downcase
      Text.new(self.to_s.downcase)
    end
    
    def split(sloch)
      self.to_encoded_string.
        # Split by <tt>sloch.to_encoded_regexp</tt>.
        gsub(sloch.to_encoded_regexp, "|").split("|", -1).
        # 
        map { |part| Text.from_encoded_string(part) }
    end
    
    private
    
    def initialize(str, encoded_str)  # :not-new:
      @str = str
      @encoded_str = encoded_str
    end
    
    # calls +f+ and returns true.
    def act(&f)
      f.()
      return true
    end
    
  end
  
  class Word
    
    # 
    # Regular expression matching #to_encoded_string().
    # 
    # It matches only Word#to_encoded_string() in Text#to_encoded_string() and
    # nothing else. It also never matches a part of Word#to_encoded_string().
    # 
    ENCODED_REGEXP = "W[01]\\h+W"
    
    def initialize(str, is_proper_name_with_dot = false)
      @str = str
      @is_proper_name_with_dot = is_proper_name_with_dot
    end
    
    def inspect
      "#{@str.inspect}#{if proper_name_with_dot? then "(.)" else "" end}"
    end
    
    def to_s
      @str
    end
    
    # 
    # See also ENCODED_REGEXP, ::from_encoded_string().
    # 
    def to_encoded_string
      r = "W#{if proper_name_with_dot? then "1" else "0" end}"
      @str.each_codepoint do |code|
        raise "character code must be 00h–FFh: #{code}" unless code.in? 0x00..0xFF
        r << code.to_s(16)
      end
      r << "W"
      return r
    end
    
    def self.from_encoded_string(encoded_str)
      Word.new(
        encoded_str[2...-1].gsub(/\h\h/) { |code| code.hex.chr },
        encoded_str[1] == "1"
      )
    end
    
    def proper_name_with_dot?
      @is_proper_name_with_dot
    end
    
  end
  
  class Sloch
    
    # 
    # +str+ must be String#squeeze_unicode_whitespace()-ed.
    # 
    def initialize(str)
      @str = str
      @encoded_regexp = Regexp.new(
        Text.new(str).to_encoded_string.
          # Escape everything except "*".
          split("*").map { |part| Regexp.escape(part) }.
          # Replace "*" with...
          join("#{Word::ENCODED_REGEXP}( ?,? ?#{Word::ENCODED_REGEXP})?")
      )
    end
    
    def to_encoded_regexp
      @encoded_regexp
    end
    
    def to_s
      @str
    end
    
  end
  
  class Memory
    
    def initialize()
      @impl = Set.new
    end
    
    # 
    # returns false once for every +x+. In other cases it returns true.
    # 
    def mentioned_before?(x)
      if @impl.include? x then
        return true
      else
        @impl.add x
        return false
      end
    end
    
  end
