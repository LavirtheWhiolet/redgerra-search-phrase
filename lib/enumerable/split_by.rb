
module Enumerable
  
  # 
  # Examples:
  # 
  #   [1, 2, 3, 4, 5, 6, 7, 8].split_by { |x| x == 3 or x == 6 }
  #     #=> [[1, 2], [4, 5], [7, 8]]
  # 
  #   [1, 2, 3, 4].split_by { |x| x == 2 or x == 3 }
  #     #=> [[1], [], [4]]
  # 
  def split_by(&condition)
    r = []
    self.each do |item|
      if condition.(item) then
        r.push []
      else
        if r.last.nil? then r.push []; end
        r.last.push item
      end
    end
    r
  end
  
end
