require 'object/not_nil'
require 'enumerable/filter'

module RandomAccessible
  
  unless RUBY_VERSION >= "2.0.0"
    
    # Prepend this module to Array.
    class ::Array
      include RandomAccessible
    end
    
    # NOTE: When Module A is included into Module B *before* any declarations
    # made in A then the effect is the same as Module A is prepended to
    # Module B (as in Ruby 2.0).
    
  end
  
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
  #   lazy_cached_filter() { |item| ... } → RandomAccessible
  # 
  # Lazy and cached version of Enumerable#filter(). It returns RandomAccessible.
  # 
  def lazy_cached_filter(&f)
    
  end
  
  private
  
  class LazyCachedFiltered
    
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
      return @cached_results[index]
    end
    
    def lazy_cached_filter(&f2)
      # Optimization.
      LazyCachedFiltered.new(@source, &LazyCachedFiltered.f1_filter_f2(@f, f2))
    end
    
    private
    
    # It is used to reduce context of lambdas.
    def self.f1_filter_f2(f1, f2)
      lambda { |item| f1.(item).filter(&f2) }
    end
    
  end
  
end

if RUBY_VERSION >= "2.0.0"
  
  class Array
    
    prepend RandomAccessible
    
  end
  
end
