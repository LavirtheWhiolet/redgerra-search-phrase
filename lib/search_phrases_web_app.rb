require 'sinatra/base'
require 'search_phrases'
require 'expiring_hash_map'
require 'random_accessible'

# 
# A web application for #search_phrases() function.
# 
# This class is abstract.
# 
class SearchPhrasesWebApp < Sinatra::Application
  
  def initialize()
    super()
  end
  
  template :layout do
    <<-ERB
      <!DOCTYPE html>
      <html>
        <head>
          <meta http-equiv="Content-Type" content="text/html; charset=utf-8">
          <title>Search Phrase</title>
        </head>
        <body>
          <%= yield %>
          <hr style="height: 1px"/>
          <center><small><a href="https://github.com/LavirtheWhiolet/search-phrase">Source code</a> | <a href="mailto:Lavir.th.Whiolet@gmail.com">Contact me</a></small></center>
        </body>
      </html>
    ERB
  end
  
  template :index do
    <<-ERB
      <form>
        Phrase part: <input name="phrase-part" size="100" type="text"/> <input type="submit" value="Search"/>
      </form>
    ERB
  end
  
  get '/' do
    erb :index
  end
  
  protected
  
  # 
  # sends +query+ to a web-search engine and returns RandomAccessible of URL's.
  # 
  # +query+ is a query for the web-search engine.
  # 
  # +browser+ is a Watir::Browser which will be used to browse the web-search
  # engine's pages.
  # 
  # This method must be redefined in subclasses.
  # 
  def search(query, browser)
    raise NoMethodError.new %(this method must be redefined in subclasses)
  end
  
  # 
  # returns 2 Watir::Browser's:
  # - A browser for passing to #search().
  # - A browser for passing to ::search_phrases().
  # 
  # This method must be redefined in subclasses.
  # 
  def new_browsers
    raise NoMethodError.new %(this method must be redefined in subclasses)
  end
  
end
