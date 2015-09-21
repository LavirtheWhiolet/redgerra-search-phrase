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
      oo = lambda { |t| "O#{t.hex_encode}O" }
      word = "W\\h+Y\\h+W"
      ws = oo.(" ")
      comma = oo.(",")
      sloch_occurence = "S\\h+S"
      exclamation = oo.("!")
      question = oo.("?")
      dot = oo.(".")
      semicolon = oo.(";")
      ellipsis = oo.("…")
      # 
      encoded_str = self.
        squeeze_unicode_whitespace.
        parse do |token, type|
          case type
          when :word
            "W#{token.downcase.hex_encode}Y#{token.hex_encode}W"
          when :other
            oo.(token)
          end
        end
      encoded_sloch_regexp = sloch.
        squeeze_unicode_whitespace.
        downcase.
        parse do |token, type|
          case type
          when :word
            "W#{token.downcase.hex_encode}Y\\h+W"
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
      encoded_str.
        gsub!(encoded_sloch_regexp) { |match| "S#{match.hex_encode}S" }
      encoded_phrases = encoded_str.
        scan(/((#{word}|#{comma}|#{ws})*#{sloch_occurence}(#{word}|#{comma}|#{ws}|#{sloch_occurence})*(#{exclamation}|#{question}|#{dot}|#{semicolon}|#{ellipsis})*)/o).map(&:first)
# #           scan(/((#{w}|#{pws})*#{s}(#{w}|#{pws})*[\!\?\.\;…]*)/o).map(&:first).
# #           # Strip bordering punctuation and whitespace.
# #           map { |encoded_phrase| encoded_phrase.gsub(/^#{pws}+|#{pws}+$/o, "") }.
        
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
      self.each_codepoint do |code|
        raise "character code must be 00h–FFh: #{code}" unless code.in? 0x00..0xFF
        r << code.to_s(16)
      end
      r
    end
    
    # Inversion of #hex_encode().
    def hex_decode
      self.gsub(/\h\h/) { |code| code.hex.chr }
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
  
#   class ::String
#     
#     # Returns phrases from this String which include +sloch+.
#     def phrases(sloch)
#       # Encode words in +str+.
#       encoded_str = self.
#         squeeze_unicode_whitespace.
#         gsub_words do |word|
#           is_proper_name_with_dot_flag =
#             if word.include? "." then "1" else "0" end
#           "W#{is_proper_name_with_dot_flag}#{word.downcase.hex_encode}Y#{word.hex_encode}W"
#         end
#       # 
#       encoded_sloch = sloch.
#         squeeze_unicode_whitespace.
#         downcase.
#         gsub_words { |downcase_sloch_word| "W[01]#{downcase_sloch_word.hex_encode}Y\\h+W" }.
#         # Replace "*" with...
#         split("*").map { |part| Regexp.escape(part) }.join("W[01]\\h+Y\\h+W( ?,? ?W[01]\\h+Y\\h+W)?").
#         #
#         to_regexp
#       # Replace sloch occurences with "S\h+S"
#       p self
#       p encoded_str
#       p encoded_sloch
#       encoded_str.gsub!(sloch) { |occurence| "S#{occurence.hex_encode}S" }
#       p encoded_str
#       [""]
# #       # 
# #       encoded_phrases = begin
# #         pws = "[\\,\\ ]"
# #         s = encoded_sloch_occurence_regexp
# #         w = encoded_word_regexp
# #         encoded_str.
# #           # Scan for all phrase candidates.
# #           scan(/((#{w}|#{pws})*#{s}(#{w}|#{pws})*[\!\?\.\;…]*)/o).map(&:first).
# #           # Strip bordering punctuation and whitespace.
# #           map { |encoded_phrase| encoded_phrase.gsub(/^#{pws}+|#{pws}+$/o, "") }.
# #           # Filter phrases (1).
# #           select do |encoded_phrase|
# # #             not encoded_phrase.empty? and
# # #             encoded_phrase.scan(/#{encoded_word_regexp}/o).size <= 20 and
# # #             not encoded_phrase =~ /W1\h+Y\h+W/
# #             true
# #           end
# #       end
# #       # Decode phrases.
# #       phrases = encoded_phrases.
# #         map do |encoded_phrase|
# #           encoded_phrase.
# #             gsub(/#{encoded_sloch_occurence_regexp}/o) { |s| s[1...-1].hex_decode }.
# #             gsub(/#{encoded_word_regexp}/o) { |w| w[/Y(\h+)W/, 1].hex_decode }
# #         end
#     end
#     
#     # Passes +block+ with each word from this String and replaces the word with
#     # the +block+'s result.
#     # 
#     # Returns this String with the words replaced.
#     # 
#     def gsub_words(&block)
#       result = ""
#       s = StringScanner.new(self)
#       until s.eos?
#         (word = (s.scan(/\'[Cc]ause/) or s.scan(/#{word_chars = "[a-zA-Z0-9\\$]+"}([\-\.\']#{word_chars})*\'?/o)) and act do
#           result << block.(word)
#         end) or
#         (other = s.getch and act do
#           result << other
#         end)
#       end
#       return result
#     end
#     
#     # Returns this String encoded into regular expression "\h+".
#     def hex_encode
#       r = ""
#       self.each_codepoint do |code|
#         raise "character code must be 00h–FFh: #{code}" unless code.in? 0x00..0xFF
#         r << code.to_s(16)
#       end
#       r
#     end
#     
#     # Inversion of #hex_encode().
#     def hex_decode
#       self.gsub(/\h\h/) { |code| code.hex.chr }
#     end
#     
#     def upcase?
#       /[a-z]/ !~ self.to_s
#     end
#     
#     def to_regexp
#       Regexp.new(self)
#     end
#     
#     private
#     
#     # Calls +f+ and returns true.
#     def act(&f)
#       f.()
#       return true
#     end
#     
#   end
  
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
