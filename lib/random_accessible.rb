require 'object/not_nil'

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
  
end

if RUBY_VERSION >= "2.0.0"
  
  class Array
    
    prepend RandomAccessible
    
  end
  
end
