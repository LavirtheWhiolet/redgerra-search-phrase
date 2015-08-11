# encoding: UTF-8
require 'strscan'
require 'object/in'
require 'web_search_result'
require 'web_search_error'
require 'random_accessible'
require 'set'

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
      r = squeeze_whitespace(sloch).strip
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

  class Text
    
    def self.parse(str)
      encoded_str = ""
      s = StringScanner.new(str)
      until s.eos?
        (abbr = s.scan(/[Ee]\. ?g\.|etc\.|i\. ?e\.|[Ss]mb\.|[Ss]mth\./) and act do
          encoded_str << Word.parse(abbr).to_encoded_string
        end) or
        (word = s.scan(/#{word_chars = "[a-zA-Z0-9\\'\\$]+"}(\-#{word_chars})*/o) and act do
          encoded_str << Word.parse(word).to_encoded_string
        end) or
        (other = s.getch and act do
          encoded_str << other
        end)
      end
      return Text.new(encoded_str)
    end
    
    def inspect
      "#<Text #{to_s.inspect}>"
    end
    
    def to_s
      @encoded_str.gsub(/#{Word::ENCODED_REGEXP}/o) do |encoded_word|
        Word[encoded_word].to_s
      end
    end
    
    def include?(sloch)
      sloch.to_encoded_regexp === @encoded_str
    end
    
    def words
      @encoded_str.scan(/#{Word::ENCODED_REGEXP}/o).map do |encoded_str|
        Word[encoded_str]
      end
    end
    
    def split(sloch)
      tmp_delimiter = "|"
      raise %(encoded string #{@encoded_str.inspect} must not contain #{tmp_delimiter.inspect}) if @encoded_str.include? tmp_delimiter
      # 
      @encoded_str.
        # Split by <tt>sloch.to_encoded_regexp</tt>.
        gsub(sloch.to_encoded_regexp, tmp_delimiter).split(tmp_delimiter, -1).
        # 
        map { |part| Text.new(part) }
    end
    
    # Accessible to Sloch, Word, Text only.
    def to_encoded_string
      @encoded_str
    end
    
    private
    
    def initialize(encoded_str)  # :nodoc:
      @encoded_str = encoded_str
    end
    
    # calls +f+ and returns true.
    def self.act(&f)
      f.()
      return true
    end
    
  end
  
  class Word
    
    # Accessible to Sloch, Word, Text only.
    ENCODED_REGEXP = "W[OX]\\h+W"
    
    # Accessible to Sloch, Word, Text only.
    def self.[](encoded_str)
      new(encoded_str)
    end
    
    # Accessible to Sloch, Word, Text only.
    def self.parse(str, is_proper_name_with_dot = false)
      encoded_str = "W#{is_proper_name_with_dot ? "X" : "O"}"
      str.each_codepoint do |code|
        raise "character code must be 00h–FFh: #{code}" unless code.in? 0x00..0xFF
        encoded_str << code.to_s(16)
      end
      encoded_str << "W"
      return Word[encoded_str]
    end
    
    def proper_name_with_dot?
      @encoded_str[1] == "X"
    end
    
    def to_s
      @encoded_str[2...-1].gsub(/\h\h/) { |code| code.hex.chr }
    end
    
    # Accessible to Sloch, Text only.
    def to_encoded_string
      @encoded_str
    end
    
    private
    
    def initialize(encoded_str)  # :nodoc:
      @encoded_str = encoded_str
    end
    
  end
  
  class Sloch
    
    def self.parse(str)
      encoded_regexp =
        Text.parse(str.downcase).to_encoded_string.
        gsub("*", "#{Word::ENCODED_REGEXP}( ?,? ?#{Word::ENCODED_REGEXP})?")
      return Sloch.new(Regexp.new(encoded_regexp))
    end
    
    # Accessible to Sloch, Word, Text only.
    def to_encoded_regexp
      @encoded_regexp
    end
    
    private
    
    def initialize(encoded_regexp)  # :nodoc:
      @encoded_regexp = encoded_regexp
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
  
    s = Sloch.parse("do * flop")
    t = Text.parse("Everybody do the flop!
      o-ne t$w'o, do it, again flop three - fo-ur.
      ONE TWO DO IT AGAI'N FLOP THREE FO-UR...
      ONE TWO DO IT AGAI'N FLOP THREE Fo-ur...
      One two undo the floppy disk three.
      Very very very very very very very very very very very very very 
      very very very very very long phrase, do the flop included anyway.
    ")
    p t.split(s)
    
end


