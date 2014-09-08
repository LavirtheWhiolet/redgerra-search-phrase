require 'sinatra/base'
require 'search_phrase'

# A web application for #search_phrase() function.
class SearchPhraseWebApp < Sinatra::Application
  
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
          <p/>
          <hr/>
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
  
end
