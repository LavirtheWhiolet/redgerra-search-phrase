# 
# This is a Rackup file for debugging web-applications of this project.
# 

$LOAD_PATH.unshift "#{File.dirname(__FILE__)}/lib"
require 'redgerra/search_phrase_web_app'
require 'google/search2'
require 'mechanize'
require 'mechanize/close'

run Redgerra::SearchPhraseWebApp.new(
  lambda { |query, browser| Google.search2(query, browser) },
  lambda { Mechanize.new },
  10
)
