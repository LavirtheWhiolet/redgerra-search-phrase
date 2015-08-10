# encoding: UTF-8
require 'sinatra/base'
require 'expiring_hash_map'
require 'redgerra/search_phrase'
require 'web_search_error'

module Redgerra

  # 
  # Web-interface for Redgerra::search_phrase().
  # 
  class SearchPhraseWebApp < Sinatra::Application
    
    # 
    # +search_web+ is a Proc which is passed with a query and a Watir::Browser,
    # sends the query to the web search engine and returns something which
    # can be passed to Redgerra::search_phrase() (as the second argument).
    # 
    # +new_web_search_browser+ is a Proc returning a new Watir::Browser eligible
    # for passing it to +search_web+.
    # 
    # +results_per_page+ is number of results to be shown until "More..."
    # button is displayed.
    # 
    # +cache_lifetime+ is how long +search+ results are cached for.
    # 
    def initialize(search_web, new_web_search_browser, results_per_page = 200, cache_lifetime = 30*60)
      super()
      @search_web = search_web
      @new_web_search_browser = new_web_search_browser
      @results_per_page = results_per_page
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
        sloch: (params[:"sloch"] || ""),
        
      }
    end
    
    get "/phrase" do
      # 
      sloch = params[:"sloch"]
      halt 400, "Sloch is not specified" if sloch.nil? or sloch.empty?
      offset = (params[:offset] || "0").to_i
      # 
      begin
        search_phrase_cached(sloch)[offset] || ""
      rescue WebSearchError => e
        halt 503, e.user_readable_message
      end
    end
    
    # Cached version of Redgerra::search_phrase().
    def search_phrase_cached(sloch)
      cached_phrases_and_browsers = @cached_phrases_and_browsers[sloch]
      if cached_phrases_and_browsers.nil?
        b1 = @new_web_search_browser.()
        web_search_results = @search_web.(%("#{sloch}"), b1)
        phrases = Redgerra::search_phrase(sloch, web_search_results)
        @cached_phrases_and_browsers[sloch] = [phrases, b1]
        return phrases
      else
        return cached_phrases_and_browsers[0]
      end
    end
    
  end

end
