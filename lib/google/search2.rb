require 'mechanize'
require 'monitor'
require 'nokogiri'
require 'object/not_nil'

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
      # 
      @cached_results = []
    end
    
    def [](index)
      mon_synchronize do
        until @cached_results[index].not_nil? or @next_page.nil?
          # Go to next page/start the search.
          begin
            
          rescue Exception => e
          end
        end
      end
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
