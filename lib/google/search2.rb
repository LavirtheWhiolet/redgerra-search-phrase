require 'mechanize'
require 'monitor'
require 'nokogiri'

module Google
  
  # 
  # This class is thread-safe.
  # 
  class SearchResults2
    
    include RandomAccessible
    include MonitorMixin
    
    def initialize(query, browser)
      # 
      @browser = begin
        # Optimize.
        browser.max_history = 0
        # Make Google to send results as for...
        browser.user_agent = "Lynx/2.8.8pre.4 libwww-FM/2.14 SSL-MM/1.4.1"
        # In case of errors...
        browser.post_connect_hooks.push(lambda do |agent, uri, response, body|
          @last_response_body = body
        end)
        #
        browser
      end
      # 
      @next_page = "https://google.com/search?q=#{CGI::escape(query)}"
    end
    
    private
    
    
    
  end
  
  # 
  # returns SearchResults2.
  # 
  # +browser+ is Mechanize which will be used to access Google. It must
  # be Mechanize#shutdown()-ed after the returned SearchResults are used.
  # 
  def search2(query, browser)
    SearchResults2.new(query, browser)
  end
  
end
