# Used by Google::search() only.
# require 'nokogiri'
# require 'uri'
# require 'cgi'
# require 'string/lchomp'
# require 'object/not_nil'
require 'monitor'
# require 'random_accessible'
# End.

require 'nokogiri'
require 'cgi'
require 'random_accessible'
require 'web_search/result'
require 'web_search/error'
require 'object/not_nil'
require 'object/not_empty'
require 'object/in'
require 'string/lchomp'

module Google
  
  # 
  # Result of Google::search().
  # 
  # This class is thread-safe.
  # 
  class SearchResultURLs
    
    include MonitorMixin
    include RandomAccessible
    
    def initialize(browser, query)
      super()
      # 
      @browser = browser
      # Search!
      @browser.goto "google.com"
      @browser.text_field(name: "q").set(query)
      @browser.button(name: "btnG").click()
      # 
      @cached_results = current_result_urls
    end
    
    # 
    # returns either URL (as String) or nil if there are no more URLs.
    # 
    def [](index)
      mon_synchronize do
        while index >= @cached_results.size and (nxt = next_page_url).not_nil?
          @browser.goto nxt
          @cached_results.concat current_result_urls
        end
        return @cached_results[index]
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
  
  class SearchResults
    
    include RandomAccessible
    
    def initialize(query, browser)
      super()
      #
      @browser = browser
      # Start searching!
      @browser.goto "https://google.com"
      @browser.text_field(name: "q").set(query)
      @browser.button(name: "btnG").click()
      # 
      @cached_results = []
      @no_more_results = false
    end
    
    # 
    # returns WebSearch::Result or nil if +index+ is out of range.
    # 
    # It may raise WebSearch::Error.
    # 
    def [](index)
      until @cached_results[index].not_nil? or @no_more_results
        current_page_html = Nokogiri::HTML(@browser.html)
        # Check if Google asks captcha.
        if current_page_html.xpath("//form[@action='CaptchaRedirect']").not_empty? then
          raise WebSearch::Error.new("Google thinks you are a bot and asks to solve a captcha")
        end
        #
        @cached_results.concat results_from current_page_html
        # Go to next page.
        next_page_url = next_page_url_from current_page_html
        if next_page_url.nil? then
          @no_more_results = true
        else
          @browser.goto next_page_url
        end
      end
      return @cached_results[index]
    end
    
    private
    
    def results_from(html)
      html.
        xpath("//div[@id='ires']/ol/li").
        map do |node|
          r = RawResult.new(
            node.xpath("h3/a/@href").first,
            node.xpath("h3/a").first,
            node.xpath("div/span").first
          )
          if r.any_property_nil? then
            r = RawResult.new(
              node.xpath("table/tbody/tr/td/h3/a/@href").first,
              node.xpath("table/tbody/tr/td/h3/a").first,
              node.xpath("table/tbody/tr/td/span[@class='st']").first
            )
          end
          if r.any_property_nil? or r.url_node.value.start_with?("/images") then
            r = nil
          end
          r
        end.
        compact.
        map do |raw_result|
          WebSearch::Result.new(
            source_page_url_from(raw_result.url_node.value),
            text_from(raw_result.page_title_node),
            text_from(
              raw_result.page_excerpt_node,
              raw_result.page_excerpt_node.xpath("span[@class='f']")
            )
          )
        end
    end
    
    def source_page_url_from(google_search_result_url)
      google_search_result_url.
        # Get parameters string.
        lchomp("/url?").
        # Split parameters.
        split(/\&(?!.*?;)/).
        # 
        select { |parameter| parameter.start_with? "q=" }.
        # 
        map { |q| CGI.unescapeHTML(q.lchomp("q=")) }.
        # 
        first
    end
    
    def text_from(node, ignored_nodes = [])
      if node.in? ignored_nodes then return ""; end
      if node.text? then return node.content; end
      if node.element? then
        return node.children.
          map { |child_node| text_from(child_node, ignored_nodes) }.
          join
      end
      return ""
    end
    
    # returns URL or nil.
    def next_page_url_from(html)
      next_page_href = html.
        xpath("//table[@id='nav']/tbody/tr/td[last()]/a/@href")[0]
      return nil if next_page_href.nil?
      return "http://google.com#{next_page_href.value}"
    end
    
    class RawResult < Struct.new :url_node, :page_title_node, :page_excerpt_node
      
      def any_property_nil?
        url_node.nil? or page_title_node.nil? or page_excerpt_node.nil?
      end
      
    end
        
  end
  
  # 
  # returns Google::SearchResultURLs.
  #
  # +browser+ is Watir::Browser which will be used to access Google.
  # 
  # Deprecated, use #search2().
  # 
  def search(query, browser)
    Google::SearchResultURLs.new(browser, query)
  end
  
  module_function :search
  
  # 
  # returns SearchResults.
  # 
  # +browser+ is Watir::Browser which will be used to access Google.
  # 
  def search2(query, browser)
    SearchResults.new(query, browser)
  end
  
  module_function :search2
  
end

require 'watir-webdriver'
b = Watir::Browser.new(:phantomjs, args: ['--disk-cache=false', '--load-images=false'])
begin
  s = Google::search2(%("do the flop"), b)
  i = 0
  loop do
    break if s[i].nil?
    puts s[i]
    i += 1
  end
ensure
  b.close()
end

