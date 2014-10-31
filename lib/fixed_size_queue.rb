
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
  attr_reader :max_size
  
end
