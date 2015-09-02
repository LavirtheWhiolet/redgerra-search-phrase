require 'mechanize'
require 'monitor'
require 'nokogiri'
require 'object/not_nil'
require 'object/in'
require 'object/not_empty'
require 'web_search_error'
require 'server_asks_captcha'
require 'web_search_result'
require 'random_accessible'
require 'cgi'
require 'stringio'

module Google
  
  # 
  # A collection of WebSearchResult-s.
  # 
  # This class is thread-safe.
  # 
  class SearchResults2
    
    include RandomAccessible
    include MonitorMixin
    
    # Accessible to Google::search2() only.
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
      @next_page_url =
        "https://google.com/search?q=#{CGI::escape(query)}" +
        if language then "&hl=#{language}" else "" end
      # It must be a Mechanize::Page and must be either nil or
      # correspond to @next_page_url.
      @next_page = nil
      # 
      @cached_results = []
    end
    
    # returns +index+-th WebSearchResult.
    # 
    # It may raise WebSearchError.
    # 
    def [](index)
      mon_synchronize do
        until @cached_results[index].not_nil? or @next_page_url.nil?
          page =
            if @next_page then
              if @next_page.uri != @next_page_url then raise %((@next_page.uri == @next_page_url) = (#{@next_page.uri.to_s.inspect} == #{@next_page_url.to_s.inspect}) = false!); end
              @next_page
            else
              rescue_browser_exceptions { @browser.get(@next_page_url) }
            end
          @cached_results.concat(web_search_results_from page.root)
          @next_page_url = next_page_url_from page.root, page.uri
          @next_page = nil
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
      a = page.xpath("//a").find do |a|
        a["href"].start_with? "/search?" and
        text_from(a).strip == "Next"
      end
      return nil unless a
      href = a["href"]
      url = "#{page_uri.scheme}://#{page_uri.host}#{href}"
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
    
    def rescue_browser_exceptions(&action)
      begin
        action.()
      #
      rescue Mechanize::ResponseCodeError => e
        # If Google asks captcha...
        if e.response_code == "503" and (captcha_form = e.page.form(action: "CaptchaRedirect")).not_nil? then
          # 
          raise ServerAsksCaptcha.new(
            # user readable message
            "Google thinks you are bot and asks to solve a captcha",
            # captcha MIME type
            "image/jpeg",
            # captcha IO function
            lambda do
              mon_synchronize do
                begin
                  @browser.get("https://google.com#{e.page.root.xpath("//img/@src").first.value}").content
                rescue Mechanize::Error
                  StringIO.new("")
                end
              end
            end,
            # submit function
            &lambda do |captcha_answer|
              mon_synchronize do
                begin
                  captcha_form.field(name: "captcha").value = captcha_answer
                  @next_page = captcha_form.submit()
                  @next_page_url = @next_page.uri
                  is_captcha_answered = true
                  nil
                rescue Mechanize::Error => e
                  return e  # for debugging purposes.
                end
              end
            end
          )
        # In case of other errors...
        else
          raise WebSearchError.new(e.page.content, e)
        end
      #
      rescue Mechanize::Error => e
        raise WebSearchError.new(e.message, e)
      end
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
    SearchResults2.new(query, language, browser)
  end
  
  module_function :search2
  
end
