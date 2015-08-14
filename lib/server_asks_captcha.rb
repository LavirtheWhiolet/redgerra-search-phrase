require 'web_search_error'

# 
# "The server requires to solve a captcha".
# 
class ServerAsksCaptcha < WebSearchError
  
  # 
  # +user_readable_message+ - see WebSearchError#new().
  # 
  # +captcha_mime_type is the value for #captcha_mime_type.
  # 
  # +captcha_io+ is the value for #captcha_io.
  # 
  # +submit+ is the implementation of #submit().
  # 
  def initialize(user_readable_message, captcha_mime_type, captcha_io, &submit)
    super(user_readable_message)
    @captcha_mime_type = captcha_mime_type
    @captcha_io = captcha_io
    @submit = submit
  end
  
  attr_reader :captcha_mime_type
  
  attr_reader :captcha_io
  
  alias captcha captcha_io
  
  # 
  # submits an answer to the captcha.
  # 
  # It may raise WebSearchError.
  # 
  def submit(captcha_answer)
    @submit.(captcha_answer)
  end
  
end
