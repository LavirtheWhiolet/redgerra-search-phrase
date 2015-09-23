# encoding: UTF-8
require 'sinatra/base'
require 'expiring_hash_map2'
require 'redgerra/search_phrase'
require 'web_search_error'
require 'server_asks_captcha'
require 'timeout'

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
    # +options+ is a Hash of options:
    # 
    # +:results_per_page+ :: A number of results to be shown until "More..."
    #                        button is displayed. Default is 200.
    # 
    # +:cache_lifetime+ :: How long +search+ results are cached for (in
    #                      seconds). Default is 25.
    # 
    # +:response_max_time+ :: Max. time to respond to a client (in seconds).
    #                         Request processing is not interrupted after the
    #                         timeout. Default is 30 minutes.
    # 
    # +:timeout_per_web_page+ :: Argument +timeout_per_page+ for
    #                            Redgerra::search_phrase(). Default is 30.
    # 
    def initialize(search_web, new_web_search_browser, options = {})
      super()
      #
      @results_per_page = options[:results_per_page] || 200
      @response_max_time = options[:response_max_time] || 25
      cache_lifetime = options[:cache_lifetime] || 30*60
      timeout_per_web_page = options[:timeout_per_web_page]
      # 
      @sessions = ExpiringHashMap2.new(cache_lifetime) do |sessions, sloch|
        browser = new_web_search_browser.()
        phrases = Redgerra::search_phrase(sloch, search_web, browser, timeout_per_web_page)
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
        sloch: (params[:"sloch"] || "")
      }
    end
    
    get "/phrase" do
      # 
      sloch = params[:sloch]
      halt 400, "Sloch is not specified" if sloch.nil? or sloch.empty?
      offset = (params[:offset] || "0").to_i
      # 
      with_session(sloch) do |session|
        begin
          # TODO: Potential DoS attack: If the phrase can not be found for
          #   a long time then background threads accumulate! They terminate
          #   all at once with the first found phrase though.
          soft_timeout(@response_max_time) { session.phrases[offset] || "" }
        rescue Timeout::Error
          halt 500, "Try again"
        rescue ServerAsksCaptcha => e
          session.server_asks_captcha = e
          halt 503, "Server asks captcha"
        rescue WebSearchError => e
          halt 503, e.user_readable_message
        end
      end
    end
    
    get "/captcha" do
      sloch = params[:sloch]
      halt 400, "Sloch is not specified" if sloch.nil? or sloch.empty?
      #
      with_session(sloch) do |session|
        e = session.server_asks_captcha
        halt 404 unless e
        headers \
          "Pragma-directive" => "no-cache",
          "Cache-directive" => "no-cache",
          "Cache-control" => "no-cache",
          "Pragma" => "no-cache",
          "Expires" => "0",
          "Content-Type" => e.captcha_mime_type,
          "Content-Length" => e.captcha_cached.length.to_s
        stream { |out| out << e.captcha_cached }
      end
    end
    
    post "/captcha" do
      sloch = params[:sloch]
      halt 400, "Sloch is not specified" if sloch.nil? or sloch.empty?
      answer = params[:answer] || ""
      #
      with_session(sloch) do |session|
        halt 404 unless session.server_asks_captcha
        session.server_asks_captcha.submit(answer)
        session.server_asks_captcha = nil
        ""
      end
    end
    
    def with_session(sloch, &f)
      s = @sessions[sloch]
      s.mon_synchronize do
        f.(s)
      end
    end
    
    # The same as Timeout::timeout but does not interrupt +block+ (it continues
    # processing in a separate Thread).
    def soft_timeout(timeout, &block)
      t = Thread.new(&block)
      t.join(timeout) or raise Timeout::Error
      t.value
    end
    
    class Session < Struct.new :browser, :phrases
      
      include MonitorMixin
      
      attr_accessor :server_asks_captcha
      
      def close()
        browser.close()
      end
      
    end
    
  end

end
