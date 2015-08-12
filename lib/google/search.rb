require 'nokogiri'
require 'cgi'
require 'random_accessible'
require 'web_search_result'
require 'web_search_error'
require 'object/not_nil'
require 'object/not_empty'
require 'object/in'
require 'string/lchomp'

module Google
  
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
    # returns WebSearchResult or nil if +index+ is out of range.
    # 
    # It may raise WebSearchError.
    # 
    def [](index)
      until @cached_results[index].not_nil? or @no_more_results
        current_page_html = Nokogiri::HTML(@browser.html)
        File.write("res.html", @browser.html)
        # Check if Google asks captcha.
        if current_page_html.xpath("//form[@action='CaptchaRedirect']").not_empty? then
          raise WebSearchError.new("Google thinks you are a bot and asks to solve a captcha")
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
      (
        # For PhantomJS.
        html.xpath("//div[@id='ires']/ol/li") + 
        # For Firefox.
        html.xpath("//div[@id='ires']/ol/div[class='srg']/div")
      ).
        map do |node|
          # For PhantomJS.
          r = RawResult.new(
            node.xpath("h3/a/@href").first,
            node.xpath("h3/a").first,
            node.xpath("div/span").first
          )
          # For PhantomJS (another version).
          if r.any_property_nil? then
            r = RawResult.new(
              node.xpath("table/tbody/tr/td/h3/a/@href").first,
              node.xpath("table/tbody/tr/td/h3/a").first,
              node.xpath("table/tbody/tr/td/span[@class='st']").first
            )
          end
#           # For Firefox.
#           if r.any_property_nil? then
#             r = RawResult.new(
#               node.xpath("div/div/h3")
#             )
#           end
          if r.any_property_nil? or r.url_node.value.start_with?("/images") then
            r = nil
          end
          r
        end.
        compact.
        map do |raw_result|
          WebSearchResult.new(
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
  # returns SearchResults.
  # 
  # +browser+ is Watir::Browser which will be used to access Google. It must
  # be Watir::Browser#close()-d after the returned SearchResults are used.
  # 
  def search(query, browser)
    SearchResults.new(query, browser)
  end
  
  module_function :search
  
end
