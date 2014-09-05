require 'object/in'

class Object
  
  # The same as <code>not self.in?(other)</code>.
  # 
  # See also Object#in?().
  # 
  def not_in?(other)
    not self.in?(other)
  end
  
end