# encoding: UTF-8
require 'strscan'
require 'object/in'
require 'web_search_result'
require 'web_search_error'
require 'random_accessible'
require 'set'
require 'string/squeeze_unicode_whitespace'

require 'open-uri'
require 'nokogiri'
require 'object/not_in'
require 'string/scrub'

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
      r = sloch.squeeze_unicode_whitespace.strip
      r = words_to_ids(r)
      r.gsub!("*", "#{WORD_ID}( ?,? ?#{WORD_ID})?")
      Regexp.new(r)
    end
    m = Memory.new
    # 
    web_search.(%("#{sloch}"), browser).
      lazy_cached_filter do |web_search_result|
        [web_search_result.page_excerpt]
      end.
      lazy_cached_filter do |text_block|
        text_block = text_block.squeeze_unicode_whitespace
        text_block_parsed = words_to_ids(text_block)
        phrases_parsed = text_block_parsed.scan(/((#{WORD_ID}|[\,\-\ ])+)/o).map(&:first)
        phrases_parsed.
          map(&:strip).
          map { |phrase_parsed| [phrase_parsed, ids_to_words(phrase_parsed)] }.
          select do |phrase_parsed, phrase|
            phrase_downcase_parsed = words_to_ids(phrase.downcase)
            (
              m.not_mentioned_before?(phrase) and
              not upcase?(phrase) and
              word_ids(phrase_parsed).size <= 20 and
              sloch_regexp === phrase_downcase_parsed and
              # There must be at least 2 words before and after sloch.
              phrase_downcase_parsed.gsub(sloch, "|").split("|", -1).all? { |part| word_ids(part).size >= 2 }
            )
          end.
          map { |phrase_parsed, phrase| phrase }
      end
  end
  
  private
  
  # returns Array of String-s.
  def self.text_blocks_from_page_at(uri)
    #
    page_io =
      begin
        open(uri)
      rescue
        return []
      end
    #
    begin
      text_blocks_from(Nokogiri::HTML(page_io))
    ensure
      page_io.close()
    end
  end
  
  # returns Array of String's.
  # 
  # +element+ is Nokogiri::Element.
  # 
  def self.text_blocks_from(element)
    text_blocks = []
    start_new_text_block = lambda do
      text_blocks.push("") if text_blocks.empty? or not text_blocks.last.empty?
    end
    this = lambda do |element|
      case element
      when Nokogiri::XML::CDATA, Nokogiri::XML::Text
        text_blocks.last.concat(element.content.scrub("_"))
      when Nokogiri::XML::Comment
        # Do nothing.
      when Nokogiri::XML::Document, Nokogiri::XML::Element
        if element.name.in? %W{ script style } then
          start_new_text_block.()
        else
          element_is_separate_text_block = element.name.not_in? %W{
            a abbr acronym b bdi bdo br code del dfn em font i img ins kbd mark
            q s samp small span strike strong sub sup time tt u wbr
          }
          string_introduced_by_element =
            case element.name
            when "br" then "\n"
            when "img" then " "
            else ""
            end
          start_new_text_block.() if element_is_separate_text_block
          text_blocks.last.concat(string_introduced_by_element)
          element.children.each(&this)
          start_new_text_block.() if element_is_separate_text_block
        end
      else
        start_new_text_block.()
      end
    end
    this.(element)
    return text_blocks
  end
  
  def self.upcase?(word)
    /[a-z]/ !~ word
  end
  
  class Text
    
    # 
    # +str+ must be String#squeeze_unicode_whitespace()-ed.
    # 
    def initialize(str)
      @str = str
    end
    
    def to_s
      @str
    end
    
    def to_encoded_string
      result = ""
      s = StringScanner.new(@str)
      until s.eos?
        (abbr = s.scan(/[Ee]\. ?g\.|etc\.|i\. ?e\.|[Ss]mb\.|[Ss]mth\./) and act do
          result << Word.new(abbr).to_encoded_string
        end) or
        (word = s.scan(/#{word_chars = "[a-zA-Z0-9\\'\\$]+"}(\-#{word_chars})*/o) and act do
          result << Word.new(word).to_encoded_string
        end) or
        (other = s.getch and act do
          result << other
        end)
      end
      return result
    end
    
    def self.from_encoded_string(encoded_str)
      Text.new(
        encoded_str.gsub(/#{Word::ENCODED_REGEXP}/o) do |encoded_word|
          Word.from_encoded_string(encoded_word).to_s
        end
      )
    end
    
    def inspect
      "#<Text #{@str.inspect}>"
    end
    
    def include?(sloch)
      sloch.to_encoded_regexp === self.to_encoded_string
    end
    
    def phrases
      self.to_encoded_string.scan(/((#{Word::ENCODED_REGEXP}|[\,\-\ ])+)/o).map(&:first).
        map(&:strip).
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
    
    def downcase
      Text.new(@str.downcase)
    end
    
    def split(sloch)
      self.to_encoded_string.
        # Split by <tt>sloch.to_encoded_regexp</tt>.
        gsub(sloch.to_encoded_regexp, "|").split("|", -1).
        # 
        map { |part| Text.from_encoded_string(part) }
    end
    
    private
    
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
    ENCODED_REGEXP = "W[OX]\\h+W"
    
    def initialize(str, is_proper_name_with_dot = false)
      @str = str
      @is_proper_name_with_dot = is_proper_name_with_dot
    end
    
    def to_s
      @str
    end
    
    def to_encoded_string
      r = "W#{if proper_name_with_dot? then "X" else "O" end}"
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
        encoded_str[1] == "X"
      )
    end
    
    def proper_name_with_dot?
      @is_proper_name_with_dot
    end
    
  end
  
  class Sloch
    
    def initialize(str)
      @encoded_regexp = Regexp.new(
        Text.new(str.squeeze_unicode_whitespace.strip.downcase).to_encoded_string.
        gsub("*", "#{Word::ENCODED_REGEXP}( ?,? ?#{Word::ENCODED_REGEXP})?")
      )
    end
    
    def to_encoded_regexp
      @encoded_regexp
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
  
    s = Sloch.new("do * flop")
    t = Text.new("Everybody do the flop!
      o-ne t$w'o, do it, again flop three - fo-ur.
      ONE TWO DO IT AGAI'N FLOP THREE FO-UR...
      ONE TWO DO IT AGAI'N FLOP THREE Fo-ur...
      One two undo the floppy disk three.
      Very very very very very very very very very very very very very 
      very very very very very long phrase, do the flop included anyway.
    ".squeeze_unicode_whitespace)
    p t.phrases
    p t.downcase.split(s)
    
end


