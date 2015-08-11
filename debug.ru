# 
# This is a Rackup file for debugging web-applications of this project.
# 

$LOAD_PATH.unshift "#{File.dirname(__FILE__)}/lib"
require 'redgerra/search_phrase_web_app'
require 'watir-webdriver'
require 'google/search'

run Redgerra::SearchPhraseWebApp.new(
  lambda { |query, browser| Google.search(query, browser) },
  lambda do
    capabilities = Selenium::WebDriver::Remote::Capabilities.phantomjs(
      "phantomjs.page.settings.userAgent" =>
      "Mozilla/5.0 (Windows NT 6.3; rv:36.0) Gecko/20100101 Firefox/36.0"
    )
    driver = Selenium::WebDriver.for :phantomjs, :desired_capabilities => capabilities
    browser = Watir::Browser.new driver
  end,
  10
)
