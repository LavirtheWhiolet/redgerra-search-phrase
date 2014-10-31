
class FixedSizeQueue
  
  def initialize(max_size)
    # TODO
  end
  
  def empty?
    size == 0
  end
  
  # Is #size() = #max_size()?
  def full?
    size == max_size
  end
  
  # Number of items currently stored in this FixedSizeQueue.
  def size
    # TODO
  end
  
  # Maximum of #size.
  def max_size
    @max_size
  end
  
  # 
  # adds +item+ to the end of this FixedSizeQueue.
  # 
  # It is an error to call this method if this FixedSizeQueue is #full?().
  # 
  def push(item)
    # TODO
  end
  
  # 
  # removes an item from the beginning of this FixedSizeQueue and returns
  # the item. If this FixedSizeQueue is #empty?() then this method does nothing
  # and returns nil.
  # 
  def pop()
    # TODO
  end
  
end
