require 'search_phrases_web_app'
require 'watir'
require 'google/search'

run SearchPhrasesWebApp.new(
  search: lambda { |query, browser| Google::search(query, browser) },
  new_seach_browser: lambda { Watir::Browser.new(:phantomjs) },
  new_seach_phrases_browser: lambda { Watir::Browser.new(:phantomjs) },
  email: 'someone@example.com',
  source_code: 'http://example.com'
)
