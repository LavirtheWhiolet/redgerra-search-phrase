# encoding: UTF-8
require 'sinatra/base'
require 'expiring_hash_map'
require 'search_phrase'

class SearchPhraseWebApp < Sinatra::Application
  
  # 
  # +search+ is a Proc which is passed with a query and a Watir::Browser, sends
  # the query to the search engine and returns RandomAccessible collection of
  # URLs.
  # 
  # +new_search_browser+ is a Proc returning a new Watir::Browser for passing
  # it to +search+.
  # 
  # +cache_lifetime+ is how long +search+ results are cached for.
  # 
  def initialize(search, new_search_browser, cache_lifetime = 30*60)
    super()
    @search = search
    @new_search_browser = new_search_browser
    @cached_phrases_and_browsers = ExpiringHashMap.new(cache_lifetime) do |phrases_and_browsers|
      phrases_and_browsers[1].close()
    end
  end
  
  private
  
  # If a phrase is not found this much times then the searching stops.
  MAX_PHRASE_NOT_FOUND_TIMES = 10
  
  APP_DIR = "#{File.dirname(__FILE__)}/search_phrase_web_app.d"
  
  set :views, "#{APP_DIR}/views"
  set :public_folder, "#{APP_DIR}/static"
  
  get "/" do
    redirect "index.html"
  end
  
  get "/index.html" do
    erb :index, locals: {
      phrase_part: (params[:"phrase-part"] || "")
    }
  end
  
  get "/phrase" do
    # 
    phrase_part = params[:"phrase-part"]
    halt 400, "Phrase part is not specified" if phrase_part.nil? or phrase_part.empty?
    offset = (params[:offset] || "0").to_i
    # 
    search_phrase_cached(phrase_part)[offset] || ""
  end
  
  # Cached version of ::search_phrase().
  def search_phrase_cached(phrase_part)
    cached_phrases_and_browsers = @cached_phrases_and_browsers[phrase_part]
    if cached_phrases_and_browsers.nil?
      b1 = @new_search_browser.()
      urls = @search.(%("#{phrase_part}"), b1)
      phrase_not_found_times = 0
      phrases = search_phrase(phrase_part, urls) do |url, phrase_found|
        if not phrase_found then phrase_not_found_times += 1
        else phrase_not_found_times = 0
        end
        need_stop = (phrase_not_found_times > MAX_PHRASE_NOT_FOUND_TIMES)
      end
      @cached_phrases_and_browsers[phrase_part] = [phrases, b1]
      return phrases
    else
      return cached_phrases_and_browsers[0]
    end
  end
  
end
