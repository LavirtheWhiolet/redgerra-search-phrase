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
  
end

class Array
  
  if RUBY_VERSION >= "2.0.0" then
    prepend RandomAccessible
  else
    module PrependedRandomAccessible
      include RandomAccessible
      Array.instance_methods.each do |method|
        self.undefine_method method
      end
    end
    include PrependedRandomAccessible
  end
  
end
