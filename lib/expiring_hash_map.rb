require 'timers'
require 'monitor'
require 'object/not_nil'

# 
# A hash map with values being automatically deleted if they are not accessed
# for a specific time period.
# 
# It must be #close()-d after it is used, otherwise it may be not
# gargbage-collectable.
# 
# This class is thread-safe.
# 
# Example:
# 
#   m = ExpiringHashMap.new(5)
#   m["a"] = 10
#   m["b"] = 20
#   sleep(3)
#   puts m["a"]  #=> 10
#   sleep(3)
#   puts m["a"]  #=> 10
#   puts m["b"]  #=> nil
#   m.close()
# 
class ExpiringHashMap
  
  include MonitorMixin
  
  # 
  # +expire_period+ is a time period after the last access to an entry of
  # the ExpiringHashMap after which the entry is deleted.
  # 
  # +on_expire+ is a function which is called when the entry is deleted due to
  # an expiration. It is passed with the entry's value.
  # 
  def initialize(expire_period, &on_expire)
    super()
    @expire_period = expire_period
    @map = {}  # key -> [value, timer]
    @timers = Timers::Group.new
    @on_expire = on_expire
    @deleting_thread = Thread.new do
      loop do
        @timers.wait
        Thread.stop if mon_synchronize { @timers.empty? }
      end
    end
  end
  
  def []=(key, value)
    mon_synchronize do
      entry = @map[key]
      if entry.not_nil?
        entry[0] = value
        entry[1].reset()
      else
        @map[key] = [
          value,
          timer = @timers.after(@expire_period) do
            mon_synchronize do
              @map.delete key
              @timers.timers.delete timer
              @on_expire.(value)
            end
          end
        ]
        @deleting_thread.wakeup
      end
      return value
    end
  end
  
  def [](key)
    mon_synchronize do
      entry = @map[key]
      if entry.not_nil?
        entry[1].reset()
        return entry[0]
      else
        return nil
      end
    end
  end
  
  def has_key?(key)
    mon_synchronize do
      return @map.has_key?(key)
    end
  end
  
  def size
    mon_synchronize do
      return @map.size
    end
  end
  
  def close()
    @deleting_thread.kill()
  end
  
end
