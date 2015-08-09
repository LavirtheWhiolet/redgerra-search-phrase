require 'search_phrase_web_app'
require 'watir-webdriver'
require 'google/search'

run SearchPhraseWebApp.new(
  lambda { |query, browser| Google.search2(query, browser) },
  lambda { Watir::Browser.new(:phantomjs) }
)
