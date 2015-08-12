require 'mechanize'
require 'monitor'
require 'nokogiri'
require 'object/not_nil'
require 'web_search_error'

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
          page =
            begin
              @browser.get(@next_page)
            rescue Mechanize::ResponseCodeError => e
              # If Google asks captcha...
              if e.response_code == "503" and e.page.root.xpath("//form[@action='CaptchaRedirect']").not_empty?
                raise WebSearchError.new("Google thinks you are bot and asks to solve a captcha")
              # In case of other errors...
              else
                raise WebSearchError.new(e.page.content)
              end
            end
          # 
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
