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
  # The resultant RandomAccessible requires O(i) of memory where i is an index
  # for #[].
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
    Filtered.new(self, &f)
  end
  
  class Filtered
    
    include RandomAccessible
    
    def initialize(source, &filter_f)
      @source = source
      @filter_f = filter_f
      @cached_results = []
      @current_source_index = 0
    end
    
    def [](index)
      until (x = @cached_results[index]).not_nil? or (y = @source[@current_source_index]).nil?
        @cached_results.concat(@filter_f.(y))
      end
      return @cached_results[index]
    end
    
  end
  
end


