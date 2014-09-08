require 'sinatra/base'
require 'search_phrases'
require 'expiring_hash_map'

# A web application for #search_phrase() function.
class SearchPhrasesWebApp < Sinatra::Application
  
  begin
    @@cache = ExpiringHashMap.new(5*60) do |entry|
      entry[1].close()
      entry[2].close()
    end
  end
  
  helpers do
    def search_phrases(phrase_part)
      
    end
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
  
end
