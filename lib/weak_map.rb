require 'weakref'
require 'monitor'

# 
# A hash map which keys of are subject to garbage collection.
# 
# It can not have keys or values which are primitive values (i. e. Fixnum,
# Symbol etc.).
# 
# It is thread-safe.
# 
class WeakMap < Hash
  
  def initialize()
    @map = {}
    @map.extend MonitorMixin
  end
  
  def [](key)
    @map.synchronize do
      return @map[key].__getobj__
    end
  end
  
  def []=(key, value)
    @map.synchronize do
      # Delete the entry when value is garbage-collected.
      ObjectSpace.define_finalizer(value) do |value_id|
        @map.synchronize do
          @map.delete key
        end
      end
      # Break strong reference to value.
      value = WeakRef.new(value)
      # Add the entry!
      @map[key] = value
      # 
      return value
    end
  end
  
  def has_key?(key)
    @map.synchronize do
      @map.has_key?(key)
    end
  end
  
  def size
    @map.synchronize do
      @map.size
    end
  end
  
end
