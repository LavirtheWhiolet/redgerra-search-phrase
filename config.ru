require 'redgerra/search_phrase_web_app'
require 'watir-webdriver'
require 'google/search'

run Redgerra::SearchPhraseWebApp.new(
  lambda { |query, browser| Google.search(query, browser) },
  lambda { Watir::Browser.new(:phantomjs) }
)
