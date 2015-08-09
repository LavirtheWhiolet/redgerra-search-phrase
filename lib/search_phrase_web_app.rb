# encoding: UTF-8
require 'sinatra/base'
require 'expiring_hash_map'
require 'search_phrase'
require 'web_search_error'

class SearchPhraseWebApp < Sinatra::Application
  
  # 
  # +search+ is a Proc which is passed with a query and a Watir::Browser, sends
  # the query to the search engine and returns RandomAccessible collection of
  # URLs.
  # 
  # +new_search_browser+ is a Proc returning a new Watir::Browser for passing
  # it to +search+.
  # 
  # +results_per_page+ is number of results to be shown until "More..."
  # button is displayed.
  # 
  # +cache_lifetime+ is how long +search+ results are cached for.
  # 
  def initialize(search, new_search_browser, results_per_page = 200, cache_lifetime = 30*60)
    super()
    @search = search
    @results_per_page = results_per_page
    @new_search_browser = new_search_browser
    @cached_phrases_and_browsers = ExpiringHashMap.new(cache_lifetime) do |phrases_and_browsers|
      phrases_and_browsers[1].close()
    end
  end
  
  private
  
  APP_DIR = "#{File.dirname(__FILE__)}/search_phrase_web_app.d"
  
  set :views, "#{APP_DIR}/views"
  set :public_folder, "#{APP_DIR}/static"
  
  get "/" do
    redirect to "index.html", false
  end
  
  get "/index.html" do
    erb :index, locals: {
      phrase_part: (params[:"phrase-part"] || ""),
      
    }
  end
  
  get "/phrase" do
    # 
    phrase_part = params[:"phrase-part"]
    halt 400, "Phrase part is not specified" if phrase_part.nil? or phrase_part.empty?
    offset = (params[:offset] || "0").to_i
    # 
    begin
      if offset > 5 then raise WebSearchError.new("Web search engine failed"); end
      search_phrase_cached(phrase_part)[offset] || ""
    rescue WebSearchError => e
      halt 503, e.user_readable_message
    end
  end
  
  # Cached version of ::search_phrase().
  def search_phrase_cached(phrase_part)
    cached_phrases_and_browsers = @cached_phrases_and_browsers[phrase_part]
    if cached_phrases_and_browsers.nil?
      b1 = @new_search_browser.()
      urls = @search.(%("#{phrase_part}"), b1)
      phrases = search_phrase(phrase_part, urls)
      @cached_phrases_and_browsers[phrase_part] = [phrases, b1]
      return phrases
    else
      return cached_phrases_and_browsers[0]
    end
  end
  
end
