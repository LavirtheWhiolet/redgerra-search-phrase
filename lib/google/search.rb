gem 'nokogiri'
gem 'watir'
require 'nokogiri'
require 'watir'
require 'uri'
require 'cgi'
require 'string/lchomp'
require 'object/not_nil'

module Google
  
  class SearchResultURLs
    
    def initialize(search_phrase)
      # Search!
      @browser = Watir::Browser.new(:phantomjs, args: ["--ignore-ssl-errors=yes"])
      @browser.goto "google.com"
      @browser.text_field(name: "q").set(search_phrase)
      @browser.button(name: "btnG").click()
      # 
      @cached_results = current_result_urls
    end
    
    # :call-seq:
    #   results[index]
    #   results[from..to]
    # 
    def [](arg)
      case arg
      when Numeric
        index = arg
        while @cached_results.size <= index and (nxt = next_page_url).not_nil?
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
    
  end
  
  # returns Google::SearchResultURLs.
  def search(phrase)
    Google::SearchResultURLs.new(phrase)
  end
  
  module_function :search
  
end
