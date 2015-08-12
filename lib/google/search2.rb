require 'mechanize'
require 'monitor'

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
        # Optimize the browser.
        begin
          browser.html_parser = DummyHTMLParser.new
          browser.max_history = 0
        end
      end
      # 
      @next_page = "https://google.com/search?q=#{CGI::escape(query)}"
    end
    
    private
    
    class DummyHTMLParser
      
      def parse(_, _, _)
        EMPTY_ARRAY_CACHED
      end
      
      private
      
      EMPTY_ARRAY_CACHED = []
      
    end
    
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
