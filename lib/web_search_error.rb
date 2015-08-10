
# Error occured during Web-search.
class WebSearchError < Exception

  def initialize(user_readable_message)
    super(user_readable_message)
  end
  
  alias user_readable_message message
  
end