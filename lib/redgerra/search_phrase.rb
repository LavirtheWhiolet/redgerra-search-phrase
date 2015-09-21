# encoding: UTF-8
require 'strscan'
require 'object/in'
require 'web_search_result'
require 'web_search_error'
require 'random_accessible'
require 'set'
require 'string/squeeze_unicode_whitespace'
require 'monitor'
require 'object/not_empty'

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
    m = Memory.new
    # 
    phrases =
      web_search.(%("#{sloch}"), "en", browser).
      lazy_cached_filter do |web_search_result|
        [web_search_result.page_excerpt]
      end.
      lazy_cached_filter do |text_block|
        text_block.phrases(sloch).
          reject { |phrase| m.mentioned_before? phrase }
      end
    #
    return ThreadSafeRandomAccessible.new(phrases)
  end
  
  private
  
  class ::String
    
    def phrases(sloch)
      # 
      other = "O\\h+O"
      word = "W[01]\\h+Y\\h+W"
      sloch_occurence = "S\\h+S"
      oo = lambda { |t| "O#{t.hex_encode}O" }
      words = lambda { |encoded_part| encoded_part.scan(/#{word}/o) }
      ws = oo.(" ")
      comma = oo.(",")
      exclamation = oo.("!")
      question = oo.("?")
      dot = oo.(".")
      semicolon = oo.(";")
      ellipsis = oo.("…")
      # Encode this string:
      #   word → /#{word}/
      #   other → /#{other}/
      # In word the /[01]/ is a flag: if the word is a proper name with "."
      # then the flag is "1", otherwise "0".
      encoded_str = self.
        squeeze_unicode_whitespace.
        parse do |token, type|
          case type
          when :word
            is_proper_name_with_dot_flag =
              if token.include? "." then "1" else "0" end
            "W#{is_proper_name_with_dot_flag}#{token.downcase.hex_encode}Y#{token.hex_encode}W"
          when :other
            oo.(token)
          end
        end
      # 
      encoded_sloch_regexp = sloch.
        squeeze_unicode_whitespace.
        downcase.
        parse do |token, type|
          case type
          when :word
            "W[01]#{token.downcase.hex_encode}Y\\h+W"
          when :other
            case token
            when "*"
              "#{word}(#{ws}?#{comma}?#{ws}?#{word})?"
            else
              oo.(token)
            end
          end
        end.
        to_regexp
      # Search for sloch and replace it with /#{sloch_occurence}/.
      encoded_str.
        gsub!(encoded_sloch_regexp) { |match| "S#{match.hex_encode}S" }
      # Search for all phrases containing the sloch.
      encoded_phrases = encoded_str.
        scan(/((#{word}|#{comma}|#{ws})*#{sloch_occurence}(#{word}|#{comma}|#{ws}|#{sloch_occurence})*(#{exclamation}|#{question}|#{dot}|#{semicolon}|#{ellipsis})*)/o).map(&:first).
        map do |encoded_phrase|
          encoded_phrase.gsub(/^(#{comma}|#{ws})+|(#{comma}|#{ws})+$/o, "")
        end
      # Filter phrases (stage 1, /#{sloch_occurence}/ is required).
      encoded_phrases.select! do |encoded_phrase|
        encoded_phrase.split(/#{sloch_occurence}/o).any? do |encoded_part|
          words.(encoded_part).not_empty?
        end
      end
      # Replace /#{sloch_occurence}/ with the original encoded strings.
      encoded_phrases.map! do |encoded_phrase|
        encoded_phrase.gsub(/#{sloch_occurence}/o) { |match| match[1...-1].hex_decode }
      end
      # Filter phrases (stage 2, phrases must be encoded).
      encoded_phrases.select! do |encoded_phrase|
        words.(encoded_phrase).size <= 20 and
        not words.(encoded_phrase).any? { |word| word[1] == "1" }
      end
      # Decode phrases.
      phrases = encoded_phrases.
        map do |encoded_phrase|
          encoded_phrase.
            gsub(/#{word}|#{other}/o) do |match|
              case match[0]
              when "W"
                match[/Y(\h+)W/, 1].hex_decode
              when "O"
                match[1...-1].hex_decode
              end
            end
        end
      # Filter phrases (stage 3, original phrases).
      phrases.select! do |phrase|
        not phrase.upcase?
      end
      phrases
    end
    
    def parse(&block)
      result = ""
      s = StringScanner.new(self)
      until s.eos?
        (word = (s.scan(/\'[Cc]ause/) or s.scan(/#{word_chars = "[a-zA-Z0-9\\$]+"}([\-\.\']#{word_chars})*\'?/o)) and act do
          result << block.(word, :word)
        end) or
        (other = s.getch and act do
          result << block.(other, :other)
        end)
      end
      return result
    end
    
    # Returns this String encoded into regular expression "\h+".
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
    
    def upcase?
      /[a-z]/ !~ self.to_s
    end
    
    def to_regexp
      Regexp.new(self)
    end
    
    # Calls +f+ and returns true.
    def act(&f)
      f.()
      return true
    end
    
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
