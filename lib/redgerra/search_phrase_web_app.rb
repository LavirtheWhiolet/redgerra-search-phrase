# encoding: UTF-8
require 'sinatra/base'
require 'expiring_hash_map2'
require 'redgerra/search_phrase'
require 'web_search_error'

module Redgerra

  # 
  # Web-interface for Redgerra::search_phrase().
  # 
  class SearchPhraseWebApp < Sinatra::Application
    
    # 
    # +search_web+ is +search_web+ argument for Redgerra::search_phrase().
    # 
    # +new_web_search_browser+ is a Proc returning a new browser eligible
    # for passing it to Redgerra::search_phrase(). The browser must respond to
    # <code>close()</code>.
    # 
    # +results_per_page+ is number of results to be shown until "More..."
    # button is displayed.
    # 
    # +cache_lifetime+ is how long +search+ results are cached for.
    # 
    def initialize(search_web, new_web_search_browser, results_per_page = 200, cache_lifetime = 30*60)
      super()
      #
      @results_per_page = results_per_page
      # 
      @sessions = ExpiringHashMap2.new(cache_lifetime) do |sessions, sloch|
        browser = new_web_search_browser.()
        phrases = Redgerra::search_phrase(sloch, search_web, browser)
        sessions[sloch] = Session.new(browser, phrases)
      end
      @sessions.on_expire = lambda do |session|
        session.close()
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
        @sessions[sloch].phrases[offset] || ""
      rescue WebSearchError => e
        halt 503, e.user_readable_message
      end
    end
    
    class Session < Struct.new :browser, :phrases
      
      def close()
        browser.close()
      end
      
    end
    
  end

end
