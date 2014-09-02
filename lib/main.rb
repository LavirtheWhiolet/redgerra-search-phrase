require 'expiring_hash_map'
require 'google/search'
require 'watir'

s = Google.search("QIP plugins", Watir::Browser.new(:phantomjs))[0..35]
p s
p s.size

# m = ExpiringHashMap.new(5) { |x| puts "DELETED: #{x}" }
# m["a"] = 10
# m["b"] = 20
# sleep(3)
# puts m["a"]  #=> 10
# sleep(3)
# puts m["a"]  #=> 10
# puts m["b"]  #=> nil
# sleep 10