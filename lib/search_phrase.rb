# encoding: UTF-8
require 'nokogiri'
require 'monitor'
require 'object/not_in'
require 'object/not_nil'
require 'strscan'
require 'random_accessible'
require 'string/replace_invalid_byte_seqs'
require 'open-uri'

# 
# Result of #search_phrase().
# 
# This class is thread-safe.
# 
class Phrases
  
  include MonitorMixin
  include RandomAccessible
  
  def initialize(phrase_part, urls, &need_stop)
    super()
    @urls = URLs.new(urls)
    @phrase_part = squeeze_and_strip_whitespace(phrase_part).downcase
    @cached_phrases = []
    @need_stop = need_stop || lambda { |url, phrase_found| false }
    @search_stopped = false
  end
  
  # :call-seq:
  #   phrases[i]
  #   phrases[x..y]
  # 
  # In the first form it returns the phrase or nil if +i+ is out of range.
  # In the second form it returns an Array of phrases (which may be empty
  # if (x..y) is completely out or range).
  # 
  def [](arg)
    mon_synchronize do
      case arg
      when Integer
        i = arg
        return get(i)
      when Range
        range = arg
        result = []
        for i in range
          x = get(i)
          result << x if x.not_nil?
        end
        return result
      end
    end
  end
  
  # 
  # returns either amount of these Phrases or :unknown.
  # 
  def size_u
    mon_synchronize do
      if @urls.current != nil and not @search_stopped then :unknown
      else @cached_phrases.size
      end
    end
  end
  
  private
  
  def get(index)
    while not @search_stopped and index >= @cached_phrases.size and @urls.current != nil
      begin
        # Read page at current URL.
        html = open(@urls.current).read.replace_invalid_byte_seqs("_")
      rescue
        # Try the next URL (if present).
        @urls.next!
        if @urls.current.not_nil? then retry
        else return nil
        end
      end
      # Search for the phrases and puts them into @cached_phrases.
      phrase_found = false
      text_blocks_from(Nokogiri::HTML(html)).each do |text_block|
        phrases_from(text_block).each do |phrase|
          if phrase.downcase.include? @phrase_part then
            phrase_found = true
            @cached_phrases.push phrase
          end
        end
      end
      # Stop searching (if needed).
      @search_stopped = @need_stop.(@urls.current, phrase_found)
      break if @search_stopped
      # 
      @urls.next!
    end
    # 
    return @cached_phrases[index]
  end
  
  WHITESPACES_REGEXP_STRING = "[\u0009-\u000D\u0020\u0085\u00A0\u1680\u180E\u2000-\u200A\u2028\u2029\u202F\u205F\u3000]+"
  WHITESPACES_REGEXP = /#{WHITESPACES_REGEXP_STRING}/
  BORDERING_WHITESPACES_REGEXP = /^#{WHITESPACES_REGEXP_STRING}|#{WHITESPACES_REGEXP_STRING}$/
  
  # convers all consecutive white-space characters to " " and strips out
  # bordering white space.
  def squeeze_and_strip_whitespace(str)
    str.
      gsub(BORDERING_WHITESPACES_REGEXP, "").
      gsub(WHITESPACES_REGEXP, " ")
  end
  
  # returns phrases (Array of String's) from +str+. All phrases are processed
  # with #squeeze_and_strip_whitespace().
  def phrases_from(str)
    str = str.gsub(WHITESPACES_REGEXP, " ")
    phrases = [""]
    s = StringScanner.new(str)
    while not s.eos?
      if (p = s.scan(/[\.\!\?…]+( |$)/)) then
        phrases.last.concat(p.chomp(" "))
        phrases.push("")
      end
      p = s.getch and phrases.last.concat(p)
    end
    phrases.pop() if phrases.last.empty?
    phrases.shift() if not phrases.empty? and phrases.first.empty?
    return phrases
  end
  
  # returns Array of String's.
  def text_blocks_from(element)
    text_blocks = [""]
    start_new_text_block = lambda { text_blocks.push("") }
    this = lambda do |element|
      case element
      when Nokogiri::XML::CDATA, Nokogiri::XML::Text
        text_blocks.last.concat element.content
      when Nokogiri::XML::Comment
        # Do nothing.
      when Nokogiri::XML::Document, Nokogiri::XML::Element
        if element.name.in? %W{ script style } then
          start_new_text_block.()
        else
          element_is_separate_text_block =
            element.name.not_in? %W{
              a abbr acronym b bdi bdo br code del dfn em font h1 h2 h3 h4 h5 h6 i
              ins kbd mark q rt s samp small span strike strong sub sup time tt u
              wbr
            }
          start_new_text_block.() if element_is_separate_text_block
          element.children.each(&this)
          start_new_text_block.() if element_is_separate_text_block
        end
      else
        start_new_text_block.()
      end
    end
    this.(element)
    text_blocks.reject!(&:empty?)
    return text_blocks
  end
  
  class URLs
    
    def initialize(urls)
      @urls = urls
      @current_index = 0
    end
    
    def current
      @urls[@current_index]
    end
    
    def next!
      @current_index += 1
      nil
    end
    
  end
  
end

# 
# searches for phrases in pages located at specified URL's.
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