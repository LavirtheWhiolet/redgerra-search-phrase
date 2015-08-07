# encoding: UTF-8
# require 'monitor'
# require 'object/not_in'
# require 'object/not_nil'
# require 'strscan'
# require 'random_accessible'
# require 'open-uri'
# require 'set'

require 'nokogiri'
require 'string/scrub'
require 'integer/chr_u'

# 
# Result of #search_phrase().
# 
# This class is thread-safe.
# 
class Phrases
  
#   include MonitorMixin
#   include RandomAccessible
#   
#   def initialize(phrase_part, urls, &need_stop)
#     super()
#     @urls = URLs.new(urls)
#     @phrase_part = squeeze_and_strip_whitespace(phrase_part).downcase
#     @cached_phrases = []
#     @cached_phrases_set = Set.new
#     @need_stop = need_stop || lambda { |url, phrase_found| false }
#     @search_stopped = false
#   end
#   
#   def initialize()
#   end
#   
#   # :call-seq:
#   #   phrases[i]
#   #   phrases[x..y]
#   # 
#   # In the first form it returns the phrase or nil if +i+ is out of range.
#   # In the second form it returns an Array of phrases (which may be empty
#   # if (x..y) is completely out or range).
#   # 
#   def [](arg)
#     mon_synchronize do
#       case arg
#       when Integer
#         i = arg
#         return get(i)
#       when Range
#         range = arg
#         result = []
#         for i in range
#           x = get(i)
#           result << x if x.not_nil?
#         end
#         return result
#       end
#     end
#   end
#   
#   # 
#   # returns either amount of these Phrases or :unknown.
#   # 
#   def size_u
#     mon_synchronize do
#       if @urls.current != nil and not @search_stopped then :unknown
#       else @cached_phrases.size
#       end
#     end
#   end
#   
# #   private
#   
#   def get(index)
#     while not @search_stopped and index >= @cached_phrases.size and @urls.current != nil
#       # 
#       page_io =
#         begin
#           open(@urls.current)
#         rescue
#           # Try the next URL (if present).
#           @urls.next!
#           if @urls.current.not_nil? then retry
#           else return nil
#           end
#         end
#       # 
#       begin
#         # Search for the phrases and puts them into @cached_phrases.
#         phrase_found = false
#         text_blocks_from(Nokogiri::HTML(page_io)).each do |text_block|
#           phrases_from(text_block).each do |phrase|
#             if phrase.downcase.include?(@phrase_part) and
#                 not @cached_phrases_set.include?(phrase) and
#                 phrase !~ /[\[\]\{\}]/ then
#               phrase_found = true
#               @cached_phrases.push phrase
#               @cached_phrases_set.add phrase
#             end
#           end
#         end
#         # Stop searching (if needed).
#         @search_stopped = @need_stop.(@urls.current, phrase_found)
#         break if @search_stopped
#         # 
#         @urls.next!
#       ensure
#         page_io.close()
#       end
#     end
#     # 
#     return @cached_phrases[index]
#   end
#   
#   def phrases_from1(url)
#     # 
#     page_io =
#       begin
#         open(url)
#       rescue
#         return []
#       end
#     #
#     begin
#       result = []
#       text_blocks_from(Nokogiri::HTML(page_io)).each do |text_block|
#         phrases_from(text_block).each do |phrase|
#           result.push(phrase)
#         end
#       end
#       return result
#     ensure
#       page_io.close()
#     end
#   end
#   
#   WHITESPACES_REGEXP_STRING = "[\u0009-\u000D\u0020\u0085\u00A0\u1680\u180E\u2000-\u200A\u2028\u2029\u202F\u205F\u3000]+"
#   WHITESPACES_REGEXP = /#{WHITESPACES_REGEXP_STRING}/
#   BORDERING_WHITESPACES_REGEXP = /^#{WHITESPACES_REGEXP_STRING}|#{WHITESPACES_REGEXP_STRING}$/
#   
#   # convers all consecutive white-space characters to " " and strips out
#   # bordering white space.
#   def squeeze_and_strip_whitespace(str)
#     str.
#       gsub(BORDERING_WHITESPACES_REGEXP, "").
#       gsub(WHITESPACES_REGEXP, " ")
#   end
#   
#   # returns phrases (Array of String's) from +str+. All phrases are processed
#   # with #squeeze_and_strip_whitespace().
#   def phrases_from(str)
#     str = str.gsub(WHITESPACES_REGEXP, " ")
#     phrases = [""]
#     s = StringScanner.new(str)
#     s.skip(/ /)
#     while not s.eos?
#       p = s.scan(/[\.\!\?…]+ /) and begin
#         p.chomp!(" ")
#         phrases.last.concat(p)
#         phrases.push("")
#       end
#       p = s.scan(/e\. ?g\.|etc\.|i\. ?e\.|smb\.|smth\.|./) and phrases.last.concat(p)
#     end
#     phrases.last.chomp!(" ")
#     phrases.pop() if phrases.last.empty?
#     phrases.shift() if not phrases.empty? and phrases.first.empty?
#     return phrases
#   end
#   
#   class URLs
#     
#     def initialize(urls)
#       @urls = urls
#       @current_index = 0
#     end
#     
#     def current
#       @urls[@current_index]
#     end
#     
#     def next!
#       @current_index += 1
#       nil
#     end
#     
#   end
  
  # returns Array of String's.
  def text_blocks_from(element)
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
  
  module Grammar
    
    # NOTE: "CS" means "character set".
    
    HYPHEN_CS = "\\-\u058A\u1400\u1806\u2010\u2011\u2E17\u2E1A\u2E40\u30A0\uFE63\uFF0D"
    WORD_CS = "a-zA-Z0-9_\u0100-\u10FFFF\\'"
    WHITESPACE_CS = "\u0009-\u000D\u0020\u0085\u00A0\u1680\u180E\u2000-\u200A\u2028\u2029\u202F\u205F\u3000"
    
    WHITESPACE = ""
    WORD = "[#{WORD_CS}]+([#{HYPHEN_CS}]+[#{WORD_CS}]+)*"
    PUNCTUATION = "([^#{WORD_CS}]|[#{HYPHEN_CS}])+"
    STOP_PUNCTUATION = "[\\.\\!\\?…]+"
    
  end
  
  class CharSet
    
    def initialize()
      @char_ranges = []
    end
    
    # NOTE: It is optimized for monotonically increasing +char_code+-s.
    def add(char_code)
      char = char_code.chr_u
      if @char_ranges.empty? then
        @char_ranges.push(char..char)
        return
      end
      if @char_ranges.last.end.succ == char then
        @char_ranges[-1] = @char_ranges.last.begin..char
      else
        @char_ranges.push(char..char)
      end
    end
    
    # Returns regular expression (in the form of String) which matches this
    # CharSet.
    def to_regexp_str
      s = @char_ranges.map do |range|
        if range.begin == range.end then esc(range.begin)
        elsif range.begin.succ == range.end then "#{esc(range.begin)}#{esc(range.end)}"
        else "#{esc(range.begin)}-#{esc(range.end)}"
        end
      end
      "[#{s.join}]"
    end
    
    # Regular expression (in the form of String) which matches any character
    # from +category+ (categories are described in this file, in "__END__"
    # section).
    def self.regexp_str(category)
      required_category = category
      r = CharSet.new
      DATA.rewind()
      DATA.each_line do |line|
        next if line.strip.empty?
        char_code, category = line.split(/\s+/, 2).map(&:strip)
        next if category != required_category
        char_code = char_code[/U+(.*)/, 1].to_i(16)
        r.add(char_code)
      end
      return r.to_regexp_str
    end
    
    private
    
    def escape_special_regexp_char(char)
      if char.ord < 128 then "\\#{char}"
      else char
      end
    end
    
    alias esc escape_special_regexp_char
    
  end

  PUNCTUATION = CharSet.regexp_str("PUNCTUATION")
  DELIMITER = CharSet.regexp_str("DELIMITER")
  
  def phrases_from(str)
    
  end
  
end

puts Phrases::PUNCTUATION
puts Phrases::DELIMITER

# p Phrases.new.phrases_from1("https://en.wikipedia.org/wiki/2013_Rosario_gas_explosion");

# 
# searches for phrases in pages located at specified URL's and returns Phrases.
# Phrases containing "{", "}", "[" or "]" are omitted.
# 
# +phrase_part+ is a part of phrases being searched for.
# 
# +urls+ is a RandomAccessible of URL's.
# 
# +need_stop+ is passed with an URL and +phrase_found+ (which is true
# if the specified phrase if found at the URL and false otherwise). It must
# return true if the searching must be stopped immediately (and no more +urls+
# should be inspected) and false otherwise. It is optional, default is to
# always return false.
# 
def search_phrase(phrase_part, urls, &need_stop)
  return Phrases.new(phrase_part, urls, &need_stop)
end

__END__
U+0020 DELIMITER
U+0021 DELIMITER
U+0022 PUNCTUATION
U+0023 PUNCTUATION
U+0024 PUNCTUATION
U+0025 DELIMITER
U+0026 PUNCTUATION
U+0027 PUNCTUATION
U+0028 DELIMITER
U+0029 PUNCTUATION
U+002A DELIMITER
U+1FFF DELIMITER