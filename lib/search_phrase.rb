gem 'nokogiri'
gem 'watir'
require 'nokogiri'
require 'watir'
require 'monitor'

# 
# Result of #search_phrase().
# 
# This class is thread-safe.
# 
class Phrases
  
  include MonitorMixin
  
  def initialize(phrase_part, urls, browser)
    @urls = urls
    @phrase_part
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
  
  def normalize(str)
    # Remove whitespace (as specified in Unicode).
    str.gsub(/[\u0009-\u000D\u0020\u0085\u00A0\u1680\u180E\u2000-\u200A\u2028\u2029\u202F\u205F\u3000]+/, ' ')
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
