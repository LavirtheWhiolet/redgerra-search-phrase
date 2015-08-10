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

p RandomAccessible.instance_methods
__END__

class Array
  
  if RUBY_VERSION >= "2.0.0" then
    prepend RandomAccessible
  else
    # [method, __old_alias__]
    ms = begin
      i = 0
      instance_methods.
        reject { |method| 
        map { |method| [method, :"__old_method_#{i.tap { i+= 1}}__"] }
    end
    # Store Array methods.
    ms.each { |method, old_alias| alias_method(old_alias, method) }
    # 
    include RandomAccessible
    # Restore Array methods.
    ms.each { |method, old_alias| alias_method(method, old_alias) }
  end
  
end

p [1,2,3].methods
