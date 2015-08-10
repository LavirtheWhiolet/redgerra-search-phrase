
module Enumerable
  
  # 
  # :call-seq:
  #   filter() { |item| ... → [] } → []
  # 
  # It passes +f+ with each item from this Enumerable, receives
  # Enumerable-s from +f+, concatenates those Enumerable-s and returns
  # them in the form of new Enumerable.
  # 
  # Examples:
  # 
  #   ["a", "b", "c"].filter { |l| [l, l+l, l+l+l] }
  #     #=> ["a", "aa", "aaa", "b", "bb", "bbb", "c", "cc", "ccc"]
  #   
  #   [1, 2, 3, 4].filter { |x| if x.odd? then [x] else [] end }
  #     #=> [1, 3]
  # 
  def filter(&f)
    r = []
    for item in self
      r.concat(f.(item).to_a)
    end
    return r
  end
  
end
