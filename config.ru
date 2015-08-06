require 'search_phrase_web_app'
require 'watir-webdriver'
require 'google/search'

run SearchPhraseWebApp.new(
  search: lambda { |query, browser| Google.search(query, browser) },
  new_search_browser: lambda { Watir::Browser.new(:phantomjs) }
)
