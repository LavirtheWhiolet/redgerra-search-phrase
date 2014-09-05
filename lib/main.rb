# encoding: UTF-8
require 'expiring_hash_map'
require 'search_phrase'
require 'watir'

browser = Watir::Browser.new(:phantomjs)
begin
  # urls = Google.search("QIP plugins")
  phrases = search_phrase("", ['http://rubydoc.info/gems/timers/4.0.0/file/README.md'], browser)
  i = 0
  while phrases[i] != nil
    p phrases[i]
    i += 1
  end
ensure
  browser.close()
end

# m = ExpiringHashMap.new(5) { |x| puts "DELETED: #{x}" }
# m["a"] = 10
# m["b"] = 20
# sleep(3)
# puts m["a"]  #=> 10
# sleep(3)
# puts m["a"]  #=> 10
# puts m["b"]  #=> nil
# sleep 10
