gem 'nokogiri'
gem 'watir'
require 'nokogiri'
require 'watir'
require 'monitor'
require 'object/not_in'
require 'object/not_nil'

# 
# Result of #search_phrase().
# 
# This class is thread-safe.
# 
class Phrases
  
  include MonitorMixin
  
  def initialize(phrase_part, urls, browser)
    @urls = urls
    @phrase_part = squeeze_and_strip_whitespace(phrase_part)
    @browser = browser
    @next_index_in_urls = 0
    @cached_phrases = []
    @size = :unknown
  end
  
  def [](index)
    mon_synchronize do
      while index >= @cached_phrases.size
        url = @urls[@next_index_in_urls]
        if url.nil?
          @size = @next_index_in_urls
          break
        end
        @next_index_in_urls += 1
        @browser.goto url
        paragraphs =
          to_text_blocks(Nokogiri::HTML(@browser.html)).split_by_delimiter
        paragraphs.each do |paragraph|
          paragraph = squeeze_and_strip_whitespace(paragraph)
          paragraph.split(".").map { |phrase| phrase << "." }.each do |phrase|
            @cached_phrases << phrase if phrase.include? @phrase_part
          end
        end
      end
      return @cached_phrases[index]
    end
  end
  
  # 
  # returns either amount of these Phrases or :unknown.
  # 
  def size_u
    mon_synchronize do
      @size
    end
  end
  
  # 
  # This method should be called if these Phrases will not be used anymore.
  # 
  def close()
    mon_synchronize do
      @urls = nil
      @phrase_part = nil
      @cached_phrases = nil
      @browser.close()
      @browser = nil
    end
  end
  
  private
  
  class DelimitedString
    
    def self.delimiter
      new(["", ""])
    end
    
    def self.[](str)
      new([str])
    end
    
    private_class_method :new
    
    def initialize(blocks)
      @blocks = blocks
    end
    
    def concat(other)
      @blocks.last.concat other.blocks.first
      @blocks.concat other.blocks[1..-1]
      return self
    end
    
    # splits this DelimitedString by DelimitedString#delimiter() and
    # returns Array of String's.
    def split_by_delimiter()
      return @blocks
    end
    
    protected
    
    attr_reader :blocks
    
  end
  
  DS = DelimitedString
  
  WHITESPACE = "[\u0009-\u000D\u0020\u0085\u00A0\u1680\u180E\u2000-\u200A\u2028\u2029\u202F\u205F\u3000]"
  BORDERING_WHITESPACES = /^#{whitespace}+|#{whitespace}+$/
  WHITESPACES = /#{whitespace}+/
  
  def squeeze_and_strip_whitespace(str)
    str.
      gsub(BORDERING_WHITESPACES, "").
      gsub(WHITESPACES, " ")
  end
  
  # returns DelimitedString having text blocks delimited with
  # DelimitedString::delimiter.
  def to_text_blocks(element)
    case element
    when Nokogiri::XML::CDATA, Nokogiri::XML::Text
      DS[str]
    when Nokogiri::XML::Comment
      DS[""]
    when Nokogiri::XML::Document, Nokogiri::XML::Element
      need_bordering_delimiters = element.name.not_in? %W{a abbr acronym b bdi
        bdo br code del dfn em font h1 h2 h3 h4 h5 h6 i ins kbd mark q rt s samp
        small span strike strong sub sup time tt u wbr}
      result = if need_bordering_delimiters then DS.delimiter else DS[""] end
      result = element.children.reduce(result) do |result, child|
        result.concat(to_text_blocks(child))
      end
      result.concat(DS.delimiter) if need_bordering_delimiters
      return result
    else
      DS.delimiter
    end
  end
  
end

# 
# searches for a phrase in pages located at specified URLs.
# 
# +phrase_part+ is a part of the phrase being searched for.
# 
# +urls+ is a collection of URLs. It must respond to <tt>urls[i]</tt> either
# with URL or with nil (if <tt>i</tt> is out of range).
# 
# +browser+ is Watir::Browser which will be used to open +urls+.
# 
def search_phrase(phrase_part, urls, browser)
  
end
