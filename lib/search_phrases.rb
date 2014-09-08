require 'nokogiri'
require 'watir'
require 'monitor'
require 'object/not_in'
require 'object/not_nil'
require 'strscan'

# 
# Result of #search_phrase().
# 
# This class is thread-safe.
# 
class Phrases
  
  include MonitorMixin
  
  def initialize(phrase_part, urls, browser)
    super()
    @urls = URLs.new(urls)
    @phrase_part = squeeze_and_strip_whitespace(phrase_part).downcase
    @browser = browser
    @cached_phrases = []
  end
  
  def [](arg)
    mon_synchronize do
      case arg
      when Integer
        index = arg
        while index >= @cached_phrases.size and @urls.current != nil
          @browser.goto @urls.current
          text_blocks_from(Nokogiri::HTML(@browser.html)).each do |text_block|
            phrases_from(text_block).each do |phrase|
              if phrase.downcase.include? @phrase_part then
                @cached_phrases.push phrase
              end
            end
          end
          @urls.next!
        end
        return @cached_phrases[index]
      when Range
        indexes = arg
        result = []
        indexes.each do |index|
          phrase = self[index]
          result.push phrase if phrase.not_nil?
        end
      else
        raise ArgumentError.new %(#{index} must be Integer or Range of Integers)
      end
    end
  end
  
  # 
  # returns either amount of these Phrases or :unknown.
  # 
  def size_u
    mon_synchronize do
      if @urls.current != nil then :unknown
      else @cached_phrases.size
      end
    end
  end
  
  private
  
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
      s.scan(/ /)
      while (p = s.scan(/[Ii]\. ?e\.|[Ee]\. ?g\.|[Ee]tc\.|\.[^ ]|[^\.]/))
        phrases.last.concat(p)
      end
      p = s.scan(/\./) and phrases.last.concat(p)
      phrases.push("") if not phrases.last.empty?
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
# searches for phrases in pages located at specified URLs.
# 
# +phrase_part+ is a part of phrases being searched for.
# 
# +urls+ is a collection of URLs. It must respond to <tt>urls[i]</tt> either
# with URL or with nil (if <tt>i</tt> is out of range).
# 
# +browser+ is Watir::Browser which will be used to open +urls+.
# 
def search_phrases(phrase_part, urls, browser)
  return Phrases.new(phrase_part, urls, browser)
end
