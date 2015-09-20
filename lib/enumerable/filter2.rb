
module Enumerable
  
  # 
  # :call-seq:
  #   filter() { |item| ... → Array } → Enumerable
  # 
  # It passes +f+ with each item from this Enumerable, receives Array-s from +f+
  # and returns their concatenation (as Enumerable).
  # 
  # Examples:
  # 
  #   ["a", "b", "c"].filter { |l| [l, l+l, l+l+l] }.to_a
  #     #=> ["a", "aa", "aaa", "b", "bb", "bbb", "c", "cc", "ccc"]
  #   
  #   [1, 2, 3, 4].filter { |x| if x.odd? then [x] else [] end }.to_a
  #     #=> [1, 3]
  # 
  def filter2(&f)
    r = []
    for item in self
      r.concat(f.(item))
    end
    return r
  end
  
end
