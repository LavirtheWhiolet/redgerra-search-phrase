# encoding: UTF-8
require 'object/not_nil'

module RandomAccessible
  
  include Enumerable
  
  # 
  # returns an item from this RandomAccessible or nil if +index+ is out of
  # range.
  # 
  def [](index)
    raise NoMethodError, %(this method must be redefined in subclasses)
  end
  
  def each
    i = 0
    while (item = self[i]).not_nil?
      yield item
      i += 1
    end
    return self
  end
  
  # 
  # :call-seq:
  #   filter() { |item| ... → Enumerable } → RandomAccessible
  # 
  # It passes +f+ with each item from this RandomAccessible, receives
  # Enumerable-s from +f+, concatenates those Enumerable-s and returns
  # them in the form of RandomAccessible.
  # 
  # Examples:
  # 
  #   ["a", "b", "c"].filter { |l| [l, l+l, l+l+l] }
  #     #=> ["a", "aa", "aaa", "b", "bb", "bbb", "c", "cc", "ccc"]
  #   
  #   [1, 2, 3, 4].filter { |x| if x.odd? then [x] else [] end }
  #     #=> [1, 3]
  # 
  def filter(&f)
  end
  
  class Filtered
    
    include RandomAccessible
    
    def initialize(source, &filter)
      @source = source
      @filter = filter
    end
    
  end
  
end
