# encoding: UTF-8
require 'sinatra/base'
require 'expiring_hash_map'

#          <meta http-equiv="Content-Type" content="text/html; charset=utf-8">
#           <hr style="height: 1px"/>
#           <center><small><a href="<%=@source_code_url%>">Source code</a> | <a href="mailto:<%=@email%>">Contact me</a></small></center>
  #{env["SCRIPT_NAME"]}

class SearchPhraseWebApp < Sinatra::Application
  
  APP_DIR = "#{File.dirname(__FILE__)}/search_phrase_web_app.d"
  
  set :views, "#{APP_DIR}/views"
  set :public_folder, "#{APP_DIR}/static"
  
  # 
  # +search+ is a Proc which is passed with a query and a Watir::Browser, sends
  # the query to the search engine and returns RandomAccessible collection of
  # URLs.
  # 
  # +new_search_browser+ is a Proc returning a new Watir::Browser for passing
  # it to +search+.
  # 
  # +cache_lifetime+ is 
  # 
  def initialize(search, new_search_browser, cache_lifetime = 30*60)
  end
  
  get "/" do
    redirect "index.html"
  end
  
  get "/index.html" do
    erb :index, locals: {
      phrase_part: (params[:"phrase-part"] || "")
    }
  end
  
  get "/phrase" do
    sleep 1
    offset = (params[:offset] || "").to_i
    if offset < 15
      "Phrase #{offset}"
    else
      body ""
    end
  end
  
end
