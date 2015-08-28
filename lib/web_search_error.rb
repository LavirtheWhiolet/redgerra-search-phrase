
# Error occured during Web-search.
class WebSearchError < Exception
  
  # 
  # +user_readable_message+ is the value for #user_readable_message.
  # 
  # +cause+ is the value for #cause.
  # 
  def initialize(user_readable_message, cause = nil)
    super(user_readable_message)
    @cause = cause
  end
  
  alias user_readable_message message
  
  # Exception caused this WebSearchError. It may be nil.
  attr_reader :cause
  
end
