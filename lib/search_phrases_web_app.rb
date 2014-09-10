# encoding: UTF-8
require 'sinatra/base'
require 'search_phrases'
require 'expiring_hash_map'
require 'random_accessible'
require 'object/not_nil'

# 
# A web application for #search_phrases() function.
# 
# This class is abstract.
# 
class SearchPhrasesWebApp < Sinatra::Application
  
  # 
  # +config+ is a Hash of options which have following meanings:
  # 
  # +:search+::                   A Proc which is passed with a query and
  #                               a Watir::Browser, sends the query to the
  #                               search engine and returns RandomAccessible
  #                               collection of URLs.
  # +:new_search_browser+::       A Proc which returns a new Watir::Browser
  #                               for passing it to +:search+ Proc.
  # +:new_search_phrases_browser+:: A Proc which returns a new Watir::Browser
  #                                 for passing it to ::search_phrases().
  # +:cache_lifetime+::           How long the internal search results cache
  #                               lives (in seconds). The more this value
  #                               the more responsive the web application is
  #                               but the more memory it uses. Default is
  #                               5 minutes.
  # +:email+::                    Contact e-mail of the web application.
  # +:source_code+::              URL of the source code of the web application.
  # +:results_per_page+::         Number of search results per page.
  #                               Default is 10.
  # 
  def initialize(config)
    super()
    @search = getopt(config, :search)
    @new_search_browser = getopt(config, :new_search_browser)
    @new_search_phrases_browser = getopt(config, :new_search_phrases_browser)
    cache_lifetime = config[cache_lifetime] || 5*60
    @email = getopt(config, :email)
    @source_code_url = getopt(config, :source_code)
    @results_per_page = config[:results_per_page] || 10
    # See #search_phrases_cached().
    @cached_phrases_and_browsers = ExpiringHashMap.new(cache_lifetime) do |phrases_and_browsers|
      phrases_and_browsers[1].close()
      phrases_and_browsers[2].close()
    end
  end
  
  private
  
  def getopt(config, option)
    config[option] or raise ArgumentError, %(#{option.inspect} is not specified)
  end
  
  # Cached version of ::search_phrases().
  def search_phrases_cached(phrase_part)
    cached_phrases_and_browsers = @cached_phrases_and_browsers[phrase_part]
    if cached_phrases_and_browsers.nil?
      b1 = @new_search_browser.()
      urls = @search.(%("#{phrase_part}"), b1)
      b2 = @new_search_phrases_browser.()
      phrases = search_phrases(phrase_part, urls, b2)
      @cached_phrases_and_browsers[phrase_part] = [phrases, b1, b2]
      return phrases
    else
      return cached_phrases_and_browsers[0]
    end
  end
  
  template :layout do
    <<-ERB
      <!DOCTYPE html>
      <html>
        <head>
          <meta http-equiv="Content-Type" content="text/html; charset=utf-8">
          <title>Search Phrase</title>
        </head>
        <body>
          <%= yield %>
          <hr style="height: 1px"/>
          <center><small><a href="<%=@source_code_url%>">Source code</a> | <a href="mailto:<%=@email%>">Contact me</a></small></center>
        </body>
      </html>
    ERB
  end
  
  def search_form(phrase_part = nil)
    <<-ERB
      <form action="/" method="get">
        Phrase part: <input name="phrase-part" size="100" type="text" value="#{Rack::Utils.escape_html(phrase_part || "")}"/> <input type="submit" value="Search"/>
      </form>
    ERB
  end
  
  template :index do
    <<-ERB
      <%=search_form%>
    ERB
  end
  
  template :search_results do
    <<-ERB
      <%=search_form(phrase_part)%>
      <p/>
      <% if current_page_phrases.empty? %>
        No phrases found.
      <% else %>
        Following phrases are found:
        <ul>
          <% for phrase in current_page_phrases %>
            <li><%=Rack::Utils.escape_html(phrase)%></li>
          <% end %>
        </ul>
      <% end %>
      <p/>
      <%=page_href_if[page - 1, "&lt;&lt; Prev", page > 0]%> | <%=page_href_if[page + 1, "Next &gt;&gt;", (page < last_known_page or not all_pages_known)]%>
      <br/>
      <% for p in 0..last_known_page %> <%=page_href_if[p, p.to_s, p != page]%> <% end %> <% if not all_pages_known then %> <%=page_href[last_known_page + 1, "…"]%> <% end %>
    ERB
  end
  
  get '/' do
    phrase_part = params[:'phrase-part']
    if phrase_part.nil?
      erb :index
    else
      phrase_part = phrase_part
      page = (params[:page] || 0).to_i
      phrases = search_phrases_cached(phrase_part)
      current_page_phrases = phrases[(page * @results_per_page)...((page + 1) * @results_per_page)]
      all_pages_known = (phrases.size_u != :unknown)
      last_known_page =
        if all_pages_known then phrases.size_u.div(@results_per_page)
        else page
        end
      page_href = lambda do |page, html|
        %(<a href="/?phrase-part=#{Rack::Utils.escape(phrase_part)}&page=#{page}">#{html}</a>)
      end
      page_href_if = lambda do |page, html, condition|
        if condition then page_href[page, html]
        else html
        end
      end
      erb :search_results, locals: {
        phrase_part: phrase_part,
        page: page,
        current_page_phrases: current_page_phrases,
        all_pages_known: all_pages_known,
        last_known_page: last_known_page,
        page_href: page_href,
        page_href_if: page_href_if
      }
    end
  end
  
end
