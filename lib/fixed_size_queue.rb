
class FixedSizeQueue
  
  def initialize(size)
    @content = [nil] * size
    @end = @begin = 0
  end
  
  def empty?
    @end == @begin
  end
  
  def full?
    
  end
  
end