# encoding: UTF-8
require 'sinatra/base'
require 'expiring_hash_map'

#          <meta http-equiv="Content-Type" content="text/html; charset=utf-8">
#           <hr style="height: 1px"/>
#           <center><small><a href="<%=@source_code_url%>">Source code</a> | <a href="mailto:<%=@email%>">Contact me</a></small></center>
  #{env["SCRIPT_NAME"]}

class SearchPhraseWebApp < Sinatra::Application
  
  set :views, File.dirname(__FILE__)
  
  get "/" do
    redirect "index.html"
  end
  
  get "/index.html" do
    erb :index, locals: {
      phrase_part: (params[:"phrase-part" || ""])
    }
  end
  
  get "/get-phrase" do
    offset = (params[:offset] || "").to_i
    if offset < 100
      "Phrase #{offset}"
    else
      ""
    end
  end
  
end
