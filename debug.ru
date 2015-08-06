# 
# This is a Rackup file for debugging web-applications of this project.
# 

$LOAD_PATH.unshift "#{File.dirname(__FILE__)}/lib"
require 'search_phrase_web_app'
require 'watir-webdriver'
require 'google/search'

run SearchPhraseWebApp.new(
  search: lambda { |query, browser| Google.search(query, browser) },
  new_search_browser: lambda { Watir::Browser.new(:phantomjs) }
)
