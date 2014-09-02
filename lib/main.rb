require 'weak_map'

m = WeakMap.new
loop do
  m[Object.new] = Object.new
  puts m.size
end
