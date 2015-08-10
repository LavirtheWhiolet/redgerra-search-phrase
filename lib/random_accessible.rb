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
  # This method requires O(1) of time. The resultant RandomAccessible requires
  # O(i_max) of memory where i_max is a maximum index passed to #[].
  # 
  def filter(&f)
    Filtered.new(self, &f)
  end
  
  private
  
  class Filtered
    
    include RandomAccessible
    
    def initialize(source, &f)
      @source = source
      @f = f
      @cached_results = []
      @current_source_index = 0
    end
    
    def [](index)
      until (x = @cached_results[index]).not_nil? or (y = @source[@current_source_index]).nil?
        @cached_results.concat(@f.(y))
        @current_source_index += 1
      end
      p @cached_results
      return @cached_results[index]
    end
    
    def filter(&f2)
      # Optimization.
      Filtered.new(@source, &Filtered.f1_then_filter_f2(@f, f2))
    end
    
    private
    
    # It is used to reduce context of lambdas.
    def self.f1_then_filter_f2(f1, f2)
      lambda { |item| f1.(item).filter(&f2) }
    end
    
  end
  
end

# class ArrayAsRandomAccessible
#   
#   include RandomAccessible
#   
#   def initialize(array)
#     @array = array
#   end
#   
#   def [](index)
#     @array[index]
#   end
#   
# end
