require 'redgerra/search_phrase_web_app'
require 'google/search2'
require 'mechanize'
require 'mechanize/close'

run Redgerra::SearchPhraseWebApp.new(
  lambda { |query, browser| Google.search2(query, browser) },
  lambda { Mechanize.new }
)
