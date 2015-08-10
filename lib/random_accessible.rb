# encoding: UTF-8
require 'object/not_nil'
require 'enumerable/filter'

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
  #   filter() { |item| ... → Array } → RandomAccessible
  # 
  # The same as Enumerable#filter() but returns RandomAccessible.
  # 
  # The resultant RandomAccessible requires O(i) of memory where i is an index
  # for #[].
  # 
  def filter(&f)
    Filtered.new(self, &f)
  end
  
  private
  
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
        @current_source_index += 1
      end
      return @cached_results[index]
    end
    
  end
  
end
