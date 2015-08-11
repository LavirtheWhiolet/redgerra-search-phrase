# encoding: UTF-8

module Redgerra
  
  # 
  # searches for phrases in Web which include +sloch+.
  # 
  # +web_search+ is a Proc which is passed with a query and +browser+,
  # passes the query to a web search engine and returns RandomAccessible
  # collection of WebSearchResult-s.
  # 
  # It may raise WebSearchError.
  # 
  def self.search_phrase(sloch, web_search, browser)
  end
  
  class ::Object
    
    def d(msg = nil)
      puts "#{if msg then "#{msg}: " else "" end}#{self.inspect}"
      return self
    end
    
  end

  search_phrase("do * flop", nil, nil).to_a.d("Result")  
  
end


