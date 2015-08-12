# 
# This is a Rackup file for debugging web-applications of this project.
# 

$LOAD_PATH.unshift "#{File.dirname(__FILE__)}/lib"
require 'redgerra/search_phrase_web_app'
require 'watir-webdriver'
require 'google/search'
require 'headless'

h = Headless.new
h.start
trap { h.destroy }
p = Selenium::WebDriver::Firefox::Profile.new

run Redgerra::SearchPhraseWebApp.new(
  lambda { |query, browser| Google.search(query, browser) },
  lambda { Watir::Browser.new :firefox, :profile => p },
  10
)
