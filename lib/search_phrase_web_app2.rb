# encoding: UTF-8
require 'sinatra/base'
require 'expiring_hash_map'


class SearchPhraseWebApp < Sinatra::Application
  
  template :layout do
    <<-ERB
      <!DOCTYPE html>
      <html>
        <head>
          <title>Search Phrase</title>
        </head>
        <body>
          <%= yield %>
        </body>
      </html>
    ERB
  end
  
#          <meta http-equiv="Content-Type" content="text/html; charset=utf-8">
#           <hr style="height: 1px"/>
#           <center><small><a href="<%=@source_code_url%>">Source code</a> | <a href="mailto:<%=@email%>">Contact me</a></small></center>
  
  template :index do
    <<-ERB
      
    ERB
  end
  
  get '/' do
    
  end
  
end