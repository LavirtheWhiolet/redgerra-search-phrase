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
  #   lazy_filter() { |item| ... → Array } → RandomAccessible
  # 
  # Lazy version of Enumerable#filter(). It returns RandomAccessible.
  # 
  # The returned RandomAccessible requires O(i_max) of memory where
  # i_max is maximum +index+ passed to its #[].
  # 
  def lazy_filter(&f)
    LazyFiltered.new(self, &f)
  end
  
  private
  
  class LazyFiltered
    
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
    
    def lazy_filter(&f2)
      # Optimization.
      LazyFiltered.new(@source, &Filtered.f1_then_lazy_filter_f2(@f, f2))
    end
    
    private
    
    # It is used to reduce context of lambdas.
    def self.f1_then_lazy_filter_f2(f1, f2)
      lambda { |item| f1.(item).lazy_filter(&f2) }
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
