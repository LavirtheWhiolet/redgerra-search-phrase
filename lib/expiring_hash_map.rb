require 'expiring_hash_map2'

# 
# Deprecated. Use ExpiringHashMap2 instead.
# 
class ExpiringHashMap
  
  def self.new(expire_period, &on_expire)
    ExpiringHashMap2.new(expire_period).tap do |h|
      h.on_expire = on_expire if on_expire
    end
  end
  
end
