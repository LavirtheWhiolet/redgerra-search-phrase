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
  # 
  # +web_search+ must return RandomAccessible collection of WebSearchResult-s.
  # The collection's RandomAccessible#[] may raise WebSearchError.
  # 
  # This method returns thread-safe RandomAccessible collection of String-s.
  # The collection's RandomAccessible#[] may raise WebSearchError.
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
            #
            not m.mentioned_before?(phrase_downcase.to_s.chomp("'")) and
            not phrase.upcase? and
            phrase.words_count <= 20 and
            phrase_downcase.include?(sloch) and
            not phrase.words.any?(&:proper_name_with_dot?) and
            phrase_downcase.split(sloch).any? { |part| part.words_count >= 1 }
          end.
          map(&:to_s)
      end
    #
    return ThreadSafeRandomAccessible.new(phrases)
  end
  
  private
  
  # Passes +block+ with each word from +str+ and replaces the word with the
  # +block+'s result.
  def gsub_words(str, &block)
    result = ""
    s = StringScanner.new(@str)
    until s.eos?
      (word = (s.scan(/\'[Cc]ause/) or s.scan(/#{word_chars = "[a-zA-Z0-9\\$]+"}([\-\.\']#{word_chars})*\'?/o)) and act do
        result << block.(word)
      end) or
      (other = s.getch and act do
        result << other
      end)
    end
    return result
  end
  
  ENCODED_WORD_REGEXP = /W\h+W/
  ENCODED_SLOCH_OCCURENCE_REGEXP = /S\h+S/
  
  # Returns +str+ with words encoded into ENCODED_WORD_REGEXP.
  def encode_words(str)
    result = ""
    s = StringScanner.new(@str)
    until s.eos?
      (word = (s.scan(/\'[Cc]ause/) or s.scan(/#{word_chars = "[a-zA-Z0-9\\$]+"}([\-\.\']#{word_chars})*\'?/o)) and act do
        is_proper_name_with_dot_flag =
          if word.include?(".") then "1" else "0" end
        result << "W#{is_proper_name_with_dot_flag}#{hex_encode(word)}W"
      end) or
      (other = s.getch and act do
        result << other
      end)
    end
    return result
  end
  
  # Inversion of #encode_words().
  def decode_words(str)
    str.gsub(ENCODED_WORD_REGEXP) { |match| hex_decode(match[2...-1]) }
  end
  
  # Returns Array of Word-s.
  # 
  # +encoded_str+ is a result of #encode_words().
  # 
  def words_from(encoded_str)
    str.scan(ENCODED_WORD_REGEXP).map do |encoded_word|
      Word.new(encoded_word[1] == "1")
    end
  end
  
  # Returns +encoded_str+ with sloch occurences encoded into
  # ENCODED_SLOCH_OCCURENCE_REGEXP.
  # 
  # +encoded_str+ is result of #encode_words().
  # 
  def encode_sloch_occurences(encoded_str, sloch)
    encoded_sloch_regexp = Regexp.new(
      encode_words(sloch).
      # Escape everything except "*".
      split("*").map { |part| Regexp.escape(part) }.
      # Replace "*" with...
      join("#{ENCODED_WORD_REGEXP}( ?,? ?#{ENCODED_WORD_REGEXP})?")
    )
    encoded_str.gsub(sloch) { |match| "S#{hex_encode(match)}S" }
  end
  
  # Inversion of #encode_sloch_occurences(). Returns only +encoded_str+ passed
  # to #encode_sloch_occurences().
  def decode_sloch_occurences(str)
    str.gsub(ENCODED_SLOCH_OCCURENCE_REGEXP) { |match| hex_decode(match[1...-1]) }
  end
  
  # Returns +str+ encoded into regular expression "\h+".
  def hex_encode(str)
    str.each_codepoint do |code|
      raise "character code must be 00h–FFh: #{code}" unless code.in? 0x00..0xFF
      r << code.to_s(16)
    end
  end
  
  # Inversion of #hex_encode().
  def hex_decode(str)
    str.gsub(/\h\h/) { |code| code.hex.chr }
  end
  
  # Calls +f+ and returns true.
  def act(&f)
    f.()
    return true
  end
  
  def upcase?(str)
    /[a-z]/ !~ self.to_s
  end
  
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
  
  class Word
    
    # Accessible to #words_from() only.
    def initialize(is_proper_name_with_dot)
      @is_proper_name_with_dot = is_proper_name_with_dot
    end
    
    def proper_name_with_dot?
      @is_proper_name_with_dot
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
  
end
