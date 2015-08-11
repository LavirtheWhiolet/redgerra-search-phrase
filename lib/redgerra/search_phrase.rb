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
    sloch_regexp = begin
      r = squeeze_whitespace(sloch).strip
      r = words_to_ids(r)
      r.gsub!("*", "#{WORD_ID}( ?,? ?#{WORD_ID})?")
      Regexp.new(r)
    end
    m = Memory.new
    # 
    ["Everybody do the flop!
      o-ne t$w'o, do it, again flop three - fo-ur.
      ONE TWO DO IT AGAI'N FLOP THREE FO-UR...
      ONE TWO DO IT AGAI'N FLOP THREE Fo-ur...
      One two undo the floppy disk three.
      Very very very very very very very very very very very very very 
      very very very very very long phrase, do the flop included anyway.
    "].
      lazy_cached_filter do |text_block|
        text_block = squeeze_whitespace(text_block)
        text_block_parsed = words_to_ids(text_block)
        phrases_parsed = text_block_parsed.scan(/((#{WORD_ID}|[\,\-\ ])+)/o).map(&:first)
        phrases_parsed.
          map(&:strip).
          map { |phrase_parsed| [phrase_parsed, ids_to_words(phrase_parsed)] }.
          select do |phrase_parsed, phrase|
            phrase_downcase_parsed = words_to_ids(phrase.downcase)
            (
              m.not_mentioned_before?(phrase) and
              word_ids(phrase_parsed).size <= 20 and
              sloch_regexp === phrase_downcase_parsed and
              # There must be at least 2 words before and after sloch.
              phrase_downcase_parsed.gsub(sloch, "|").split("|", -1).all? { |part| word_ids(part).d.size >= 2 }
            )
          end.
          map { |phrase_parsed, phrase| phrase }
      end
  end
  
  WORD_ID = "W\\h+W"
  
  # returns IDs from +str+.
  # 
  # +str+ is a String processed with ::words_to_ids().
  # 
  def self.word_ids(str)
    str.scan(/#{WORD_ID}/o)
  end
  
  # converts all consecutive white-space characters to " ".
  def self.squeeze_whitespace(str)
    str.gsub(/[\u0009-\u000D\u0020\u0085\u00A0\u1680\u180E\u2000-\u200A\u2028\u2029\u202F\u205F\u3000]+/, " ")
  end
  
  # 
  # replaces words in +text+ with IDs. WORD_ID matches the IDs, it never
  # matches anything else or a part of the ID.
  # 
  # +text+ must be #squeeze_whitespace()-ed.
  # 
  def self.words_to_ids(text)
    # 
    to_id = lambda do |word|
      r = "W"
      word.each_codepoint do |code|
        raise "character code must be 00h–FFh: #{code}" unless code.in? 0x00..0xFF
        r << code.to_s(16)
      end
      r << "W"
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
    text.gsub(/#{WORD_ID}/o) { |id| id[1...-1].gsub(/\h\h/) { |code| code.hex.chr } }
  end
  
  # calls +f+ and returns true.
  def self.act(&f)
    f.()
    return true
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
  
  class ::Object
    
    def d(msg = nil)
      puts "#{if msg then "#{msg}: " else "" end}#{self.inspect}"
      return self
    end
    
  end
  
  search_phrase("do * flop", nil, nil).to_a.d("Result")  
  
end


