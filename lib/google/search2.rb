require 'mechanize'
require 'monitor'
require 'nokogiri'
require 'object/not_nil'
require 'object/in'
require 'object/not_empty'
require 'web_search_error'
require 'web_search_result'
require 'random_accessible'
require 'cgi'

module Google
  
  # 
  # This class is thread-safe.
  # 
  class SearchResults2
    
    include RandomAccessible
    include MonitorMixin
    
    def initialize(query, language, browser)
      super()
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
      @next_page_url = "https://google.com/search?q=#{CGI::escape(query)}"
      # 
      @cached_results = []
    end
    
    def [](index)
      mon_synchronize do
        until @cached_results[index].not_nil? or @next_page_url.nil?
          # Go to next page/start the search.
          page =
            begin
              @browser.get(@next_page_url)
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
          @cached_results.concat(web_search_results_from page.root)
          #
          @next_page_url = next_page_url_from page.root, page.uri
        end
        return @cached_results[index]
      end
    end
    
    private
    
    def web_search_results_from(page)
      results = []
      page.xpath("//table").each do |table|
        p = table.previous_sibling
        next unless p and p.name == "p"
        raw_urls_and_titles = (p.xpath("a") + table.xpath("tr/td/a")).
          map do |a|
            [
              a.attribute("href").value,
              text_from(a, a.xpath("img")).strip
            ]
          end.
          select do |raw_url, title|
            title.not_empty? and
            raw_url.start_with?("/url?")
          end
        next if raw_urls_and_titles.empty?
        raw_url, title = *(raw_urls_and_titles.first)
        url = param_value(raw_url, "q")
        excerpt_node = table.xpath("tr/td/font").last
        next unless excerpt_node
        excerpt = text_from(excerpt_node,
          (excerpt_node.xpath("font") + excerpt_node.xpath("a"))
        )
        excerpt = excerpt.sub(/\s*\-\s*\-\s*$/, "")
        results << WebSearchResult.new(url, title, excerpt)
      end
      return results
    end
    
    def text_from(node, ignored_nodes = [])
      if node.in? ignored_nodes then return ""
      elsif node.text? then return node.content
      elsif node.element? then
        return node.children.
          map { |child_node| text_from(child_node, ignored_nodes) }.
          join
      else return ""
      end
    end
    
    def next_page_url_from(page, page_uri)
      href = page.xpath("//a[img[@src='nav_next_2.gif']]/@href").first
      return nil unless href
      url = "#{page_uri.scheme}://#{page_uri.host}#{href.value}"
      return nil if url == @next_page_url
      url
    end
    
    def param_value(url, param_name)
      param_prefix = "#{param_name}="
      r = (url[/\?(.*)$/, 1] || "").
        split(/\&(?!.*?;)/).
        find { |param| param.start_with? param_prefix }
      return nil unless r
      CGI::unescape(r[param_prefix.size..-1])
    end
    
  end
  
  # 
  # returns SearchResults2.
  # 
  # +language+ is a preferred language of results. It is a two-character code
  # (e. g., "en", "ru", "de").
  # 
  # +browser+ is Mechanize which will be used to access Google. It must
  # be Mechanize#shutdown()-ed after the returned SearchResults are used.
  # 
  def search2(query, language = nil, browser)
    SearchResults2.new(query, browser)
  end
  
  module_function :search2
  
end
