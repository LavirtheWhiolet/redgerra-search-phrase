# encoding: UTF-8
require 'strscan'
require 'object/in'
require 'web_search_result'
require 'web_search_error'
require 'random_accessible'
require 'set'
require 'string/squeeze_unicode_whitespace'
require 'monitor'

# For Redgerra::text_blocks_from*().
require 'open-uri'
require 'nokogiri'
require 'object/not_in'
require 'string/scrub'

module Redgerra
  
  # 
  # searches for phrases in WWW which include +sloch+.
  # 
  # +web_search+ is a Proc which queries a web search engine (such as Yandex,
  # Google, DuckDuckGo or other). It is passed with:
  # - the query;
  # - preferred language (a two-letter code, e. g.: "en", "ru", fr");
  # - +browser+.
  # +web_search+ must return RandomAccessible collection of WebSearchResult-s
  # and may raise WebSearchError.
  # 
  # This method returns thread-safe RandomAccessible collection of String-s and
  # may raise WebSearchError.
  # 
  def self.search_phrase(sloch, web_search, browser)
    #
    sloch = Sloch.new(sloch.squeeze_unicode_whitespace.strip.downcase)
    m = Memory.new
    # 
    phrases =
      web_search.(%("#{sloch}"), "en", browser).
      lazy_cached_filter do |web_search_result|
        [web_search_result.page_excerpt]
      end.
      lazy_cached_filter do |text_block|
        Text.new(text_block.squeeze_unicode_whitespace).
          phrases.
          select do |phrase|
            phrase_downcase = phrase.downcase
            phrase_downcase_split_by_sloch = phrase_downcase.split(sloch)
            #
            not m.mentioned_before?(phrase.to_s) and
            not phrase.upcase? and
            phrase.words_count <= 20 and
            phrase_downcase.include?(sloch) and
            not phrase.words.any?(&:proper_name_with_dot?) and
            (
              phrase_downcase_split_by_sloch.first.words_count >= 1 or
              phrase_downcase_split_by_sloch.last.words_count >= 1
            ) and
            phrase_downcase_split_by_sloch[1...-1].all? { |part| part.words_count >= 1 }
          end.
          map(&:to_s)
      end
    #
    return ThreadSafeRandomAccessible.new(phrases)
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
      self.to_encoded_string.scan(/((#{Word::ENCODED_REGEXP}|#{punctuation_and_whitespace})+)/o).map(&:first).
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
        gsub("*", "#{Word::ENCODED_REGEXP}( ?,? ?#{Word::ENCODED_REGEXP})?")
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
  
  class ThreadSafeRandomAccessible
    
    include RandomAccessible
    include MonitorMixin
    
    def initialize(source)
      super()
      @source = source
    end
    
    def [](index)
      mon_synchronize do
        @source[index]
      end
    end
    
  end
  
end
