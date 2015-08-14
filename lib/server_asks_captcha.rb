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
  # +captcha_io_f+ is a function returning value of #captcha_io.
  # 
  # +submit_f+ is the implementation of #submit().
  # 
  def initialize(user_readable_message, captcha_mime_type, captcha_io_f, &submit_f)
    super(user_readable_message)
    @captcha_mime_type = captcha_mime_type
    @captcha_io_f = captcha_io_f
    @submit_f = submit_f
  end
  
  attr_reader :captcha_mime_type
  
  # 
  # IO for reading captcha content.
  # 
  # It may return a new IO on each call.
  # 
  def captcha_io
    @captcha_io_f.()
  end
  
  alias captcha captcha_io
  
  # Cached version of #captcha_io (in the form of String).
  def captcha_cached
    @captcha_cached ||= captcha_io.().read
  end
  
  # 
  # submits an answer to the captcha.
  # 
  # It may raise WebSearchError.
  # 
  def submit(captcha_answer)
    @submit_f.(captcha_answer)
  end
  
end
