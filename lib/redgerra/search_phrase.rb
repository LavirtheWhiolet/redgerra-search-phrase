# encoding: UTF-8
require 'strscan'
require 'object/in'

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
  end
  
  WORD_ID = "\\h+"
  
  # converts all consecutive white-space characters to " ".
  def self.squeeze_whitespace(str)
    str.gsub(/[\u0009-\u000D\u0020\u0085\u00A0\u1680\u180E\u2000-\u200A\u2028\u2029\u202F\u205F\u3000]+/o, " ")
  end
  
  # 
  # replaces words in +text+ with IDs (which can be matched with WORD_ID regular
  # expression; WORD_ID matches these IDs and nothing more).
  # 
  # +text+ must be #squeeze_whitespace()-ed.
  # 
  def self.words_to_ids(text)
    # Utils.
    to_id = lambda do |word|
      r = ""
      word.each_codepoint do |code|
        raise "character code must be 00h–FFh: #{code}" unless code.in? 0x00..0xFF
        r << code.to_s(16)
      end
      r
    end
    # Implementation.
    result = ""
    s = StringScanner.new(text)
    until s.eos?
      (abbr = s.scan(/[Ee]\. ?g\.|etc\.|i\. ?e\.|[Ss]mb\.|[Ss]mth\./o) and act do
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

#   search_phrase("do * flop", nil, nil).to_a.d("Result")  
  
end


