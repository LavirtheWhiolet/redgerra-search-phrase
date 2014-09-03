gem 'nokogiri'
gem 'watir'
require 'nokogiri'
require 'watir'
require 'monitor'
require 'object/not_in'

# 
# Result of #search_phrase().
# 
# This class is thread-safe.
# 
class Phrases
  
  include MonitorMixin
  
  def initialize(phrase_part, urls, browser)
    @urls = urls
    @phrase_part = squeeze_whitespace(phrase_part)
    @browser = browser
  end
  
  def [](index)
  end
  
  # 
  # returns either amount of these Phrases or :unknown.
  # 
  def size_u
  end
  
  # 
  # This method should be called if these Phrases will not be used anymore.
  # 
  def close()
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
  
  def squeeze_whitespace(str)
    str.gsub(
      /[\u0009-\u000D\u0020\u0085\u00A0\u1680\u180E\u2000-\u200A\u2028\u2029\u202F\u205F\u3000]+/,
      ' '
    )
  end
  
  def to_delimited_string(element)
    case element
    when Nokogiri::XML::CDATA, Nokogiri::XML::Text
      DS.delimiter.concat(DS[str]).concat(DS.delimiter)
    when Nokogiri::XML::Comment
      DS[""]
    when Nokogiri::XML::Document, Nokogiri::XML::Element
      need_bordering_delimiters = element.name.not_in? %W{a abbr acronym b bdi
        bdo br code del dfn em font h1 h2 h3 h4 h5 h6 i ins kbd mark q rt s samp
        small span strike strong sub sup time tt u wbr}
      result = if need_bordering_delimiters then DS.delimiter else DS[""] end
      result = element.children.reduce(result) do |result, child|
        result.concat(to_delimited_string(child))
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
