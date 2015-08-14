require 'web_search_error'

# 
# "The server requires to solve a captcha".
# 
class ServerAsksCaptcha < WebSearchError
  
  # 
  # +user_readable_message+ - see WebSearchError#new().
  # 
  # +captcha_uri+ is the value for #captcha_uri.
  # 
  # +submit+ is the implementation of #submit().
  # 
  def initialize(user_readable_message, captcha_uri, &submit)
    super(user_readable_message)
    @captcha_uri = captcha_uri
  end
  
  attr_reader :captcha_uri
  
  # 
  # submits an answer to the captcha.
  # 
  # It may raise WebSearchError.
  # 
  def submit(captcha_answer)
    @submit.(captcha_answer)
  end
  
end