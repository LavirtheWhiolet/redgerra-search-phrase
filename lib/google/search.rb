gem 'nokogiri'
gem 'watir'
require 'nokogiri'
require 'uri'
require 'cgi'
require 'string/lchomp'
require 'object/not_nil'

module Google
  
  class SearchResultURLs
    
    def initialize(browser, query)
      # 
      @browser = browser
      # Search!
      @browser = Watir::Browser.new(:phantomjs, args: ["--ignore-ssl-errors=yes"])
      @browser.goto "google.com"
      @browser.text_field(name: "q").set(query)
      @browser.button(name: "btnG").click()
      # 
      @cached_results = current_result_urls
    end
    
    # :call-seq:
    #   results[index]
    #   results[from..to]
    # 
    # returns either URL (as String) or nil if there are no more URLs.
    # 
    def [](arg)
      case arg
      when Numeric
        index = arg
        while index >= @cached_results.size and (nxt = next_page_url).not_nil?
          @browser.goto nxt
          @cached_results.concat current_result_urls
        end
        return @cached_results[index]
      when Range
        range = arg
        range.reduce([]) { |result, index| result << self[index] }
      else
        raise ArgumentError.new %(either Numeric or Range is required)
      end
    end
    
    private
    
    # returns next search results page URL or nil.
    def next_page_url
      next_page_href = Nokogiri::HTML(@browser.html).
        xpath("//table[@id='nav']/tbody/tr/td[last()]/a/@href")[0]
      return nil if next_page_href.nil?
      return "http://google.com#{next_page_href.value}"
    end
    
    # Result URLs which are currently loaded by +@browser+.
    def current_result_urls
      Nokogiri::HTML(@browser.html).
        xpath("//div[@id='ires']/ol/li/h3/a/@href").
        map(&:value).
        reject { |url| url.start_with? "/images" }.
        map do |url|
          q_urls = url.
            # Get query.
            lchomp("/url?").
            # Split parameters.
            split(/\&(?!.*?;)/).
            # Leave only "q" parameter.
            select { |parameter| parameter.start_with? "q=" }.
            # Extract the "q"-URL.
            map { |parameter| CGI.unescapeHTML(parameter.lchomp("q=")) }
          q_urls[0]
        end.
        compact
    end
    
    # The Google::SearchResultURLs must be closed if they would not be used
    # anymore.
    def close()
      @browser.close()
      @browser = nil
      @cached_results = nil
    end
    
  end
  
  # 
  # returns Google::SearchResultURLs.
  #
  # +browser+ is Watir::Browser which will be used to access Google.
  # 
  def search(query, browser)
    Google::SearchResultURLs.new(browser, query)
  end
  
  module_function :search
  
end
