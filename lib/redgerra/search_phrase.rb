# encoding: UTF-8
require 'strscan'
require 'object/in'
require 'web_search_result'
require 'web_search_error'
require 'random_accessible'
require 'set'

module Redgerra
  
  # 
  # searches for phrases in Web which include +sloch+.
  # 
  # +web_search+ is a Proc which is passed with a query and +browser+,
  # passes the query to a web search engine and returns RandomAccessible
  # collection of WebSearchResult-s.
  # 
  # It may raise WebSearchError.
  # 
  def self.search_phrase(sloch, web_search, browser)
    #
    sloch = begin
      sloch = " #{squeeze_whitespace(sloch).strip} "
      sloch = words_to_ids(sloch)
      sloch.gsub!("*", "#{WORD_ID}( ?,? ?#{WORD_ID})?")
      Regexp.new(sloch)
    end
    m = Memory.new
    # 
    ["Everybody do the flop!
      o-ne t$w'o, do it, again flop three - fo-ur.
      ONE TWO DO IT AGAI'N FLOP THREE FO-UR...
      ONE TWO DO IT AGAI'N FLOP THREE Fo-ur...
      Very very very very very very very very very very very very very 
      very very very very very long phrase, do the flop included anyway.
    "].
      lazy_cached_filter do |text_block|
        text_block = squeeze_whitespace(text_block)
        text_block = words_to_ids(text_block)
        phrases = text_block.scan(/(#{WORD_ID}|[\,\-\ ])/o).map(&:first).
          map(&:strip)
        phrases.select do |phrase|
          
        end
      end
  end
  
  WORD_ID = "\\h+"
  
  # converts all consecutive white-space characters to " ".
  def self.squeeze_whitespace(str)
    str.gsub(/[\u0009-\u000D\u0020\u0085\u00A0\u1680\u180E\u2000-\u200A\u2028\u2029\u202F\u205F\u3000]+/, " ")
  end
  
#   # Adds " " to the beginning and the end of +str+ if they are not there yet.
#   # 
#   # +str+ must be #squeeze_whitespace()-ed.
#   # 
#   # Examples:
#   # 
#   #   enclose_with_whitespace("abc")    #=> " abc "
#   #   enclose_with_whitespace(" abc ")  #=> " abc "
#   #   enclose_with_whitespace(" abc")   #=> " abc "
#   # 
#   def self.enclose_with_whitespace(str)
#     " #{str.strip} "
#   end
  
  # 
  # replaces words in +text+ with IDs (which can be matched with WORD_ID regular
  # expression; WORD_ID matches these IDs and nothing more).
  # 
  # +text+ must be #squeeze_whitespace()-ed.
  # 
  def self.words_to_ids(text)
    # 
    to_id = lambda do |word|
      r = ""
      word.each_codepoint do |code|
        raise "character code must be 00h–FFh: #{code}" unless code.in? 0x00..0xFF
        r << code.to_s(16)
      end
      r
    end
    # Parse!
    result = ""
    s = StringScanner.new(text)
    until s.eos?
      (abbr = s.scan(/[Ee]\. ?g\.|etc\.|i\. ?e\.|[Ss]mb\.|[Ss]mth\./) and act do
        result << to_id.(abbr)
      end) or
      (word = s.scan(/#{word_chars = "[a-zA-Z0-9\\'\\$]+"}(\-#{word_chars})*/o) and act do
        result << to_id.(word)
      end) or
      (other = s.getch and act do
        result << other
      end)
    end
    return result
  end
  
  # Inverse function of ::words_to_ids().
  def self.ids_to_words(text)
    text.gsub(/\h\h/) { |code| code.hex.chr }
  end
  
  # calls +f+ and returns true.
  def self.act(&f)
    f.()
    return true
  end
  
  class ::Object
    
    def d(msg = nil)
      puts "#{if msg then "#{msg}: " else "" end}#{self.inspect}"
      return self
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
        @impl.add x
        return true
      else
        return false
      end
    end
    
    # Inversion of #mentioned_before?().
    def not_mentioned_before?(x)
      not mentioned_before?(x)
    end
    
  end
  
#   search_phrase("do * flop", nil, nil).to_a.d("Result")  
  
end


