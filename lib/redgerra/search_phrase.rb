# encoding: UTF-8
# require 'nokogiri'
# require 'monitor'
# require 'object/not_in'
# require 'object/not_nil'
# require 'strscan'
# require 'random_accessible'
# require 'string/scrub'
# require 'open-uri'
# require 'set'
# require 'web_search_result'
# require 'web_search_error'

require 'web_search_result'
require 'web_search_error'
require 'random_accessible'
require 'set'

require 'open-uri'
require 'nokogiri'
require 'object/not_in'
require 'string/scrub'

module Redgerra

#   # 
#   # Result of Redgerra::search_phrase().
#   # 
#   # This class is thread-safe.
#   # 
#   class Phrases
#     
#     include MonitorMixin
#     include RandomAccessible
#     
#     def initialize(sloch, web_search_results)
#       super()
#       @urls = URLs.new(web_search_results)
#       @sloch = squeeze_and_strip_whitespace(sloch).downcase
#       @cached_phrases = []
#       @cached_phrases_set = Set.new
#       @search_stopped = false
#     end
#     
#     # :call-seq:
#     #   phrases[i]
#     #   phrases[x..y]
#     # 
#     # In the first form it returns the phrase or nil if +i+ is out of range.
#     # In the second form it returns an Array of phrases (which may be empty
#     # if (x..y) is completely out or range).
#     # 
#     def [](arg)
#       mon_synchronize do
#         case arg
#         when Integer
#           i = arg
#           return get(i)
#         when Range
#           range = arg
#           result = []
#           for i in range
#             x = get(i)
#             result << x if x.not_nil?
#           end
#           return result
#         end
#       end
#     end
#     
#     # 
#     # returns either amount of these Phrases or :unknown.
#     # 
#     def size_u
#       mon_synchronize do
#         if @urls.current != nil and not @search_stopped then :unknown
#         else @cached_phrases.size
#         end
#       end
#     end
#     
#     private
#     
#     def get(index)
#       while not @search_stopped and index >= @cached_phrases.size and @urls.current != nil
#         # 
#         page_io =
#           begin
#             open(@urls.current)
#           rescue
#             # Try the next URL (if present).
#             @urls.next!
#             if @urls.current.not_nil? then retry
#             else return nil
#             end
#           end
#         # 
#         begin
#           # Search for the phrases and puts them into @cached_phrases.
#           phrase_found = false
#           text_blocks_from(Nokogiri::HTML(page_io)).each do |text_block|
#             phrases_from(text_block).each do |phrase|
#               if phrase.downcase.include?(@sloch) and
#                   not @cached_phrases_set.include?(phrase) and
#                   phrase !~ /[\[\]\{\}]/ then
#                 phrase_found = true
#                 @cached_phrases.push phrase
#                 @cached_phrases_set.add phrase
#               end
#             end
#           end
#           # 
#           @urls.next!
#         ensure
#           page_io.close()
#         end
#       end
#       # 
#       return @cached_phrases[index]
#     end
#     
#     WHITESPACES_REGEXP_STRING = "[\u0009-\u000D\u0020\u0085\u00A0\u1680\u180E\u2000-\u200A\u2028\u2029\u202F\u205F\u3000]+"
#     WHITESPACES_REGEXP = /#{WHITESPACES_REGEXP_STRING}/
#     BORDERING_WHITESPACES_REGEXP = /^#{WHITESPACES_REGEXP_STRING}|#{WHITESPACES_REGEXP_STRING}$/
#     
#     # convers all consecutive white-space characters to " " and strips out
#     # bordering white space.
#     def squeeze_and_strip_whitespace(str)
#       str.
#         gsub(BORDERING_WHITESPACES_REGEXP, "").
#         gsub(WHITESPACES_REGEXP, " ")
#     end
#     
#     # returns phrases (Array of String's) from +str+. All phrases are processed
#     # with #squeeze_and_strip_whitespace().
#     def phrases_from(str)
#       str = str.gsub(WHITESPACES_REGEXP, " ")
#       phrases = [""]
#       s = StringScanner.new(str)
#       s.skip(/ /)
#       while not s.eos?
#         p = s.scan(/[\.\!\?…]+ /) and begin
#           p.chomp!(" ")
#           phrases.last.concat(p)
#           phrases.push("")
#         end
#         p = s.scan(/e\. ?g\.|etc\.|i\. ?e\.|smb\.|smth\.|./) and phrases.last.concat(p)
#       end
#       phrases.last.chomp!(" ")
#       phrases.pop() if phrases.last.empty?
#       phrases.shift() if not phrases.empty? and phrases.first.empty?
#       return phrases
#     end
#     
#     # returns Array of String's.
#     def text_blocks_from(element)
#       text_blocks = []
#       start_new_text_block = lambda do
#         text_blocks.push("") if text_blocks.empty? or not text_blocks.last.empty?
#       end
#       this = lambda do |element|
#         case element
#         when Nokogiri::XML::CDATA, Nokogiri::XML::Text
#           text_blocks.last.concat(element.content.scrub("_"))
#         when Nokogiri::XML::Comment
#           # Do nothing.
#         when Nokogiri::XML::Document, Nokogiri::XML::Element
#           if element.name.in? %W{ script style } then
#             start_new_text_block.()
#           else
#             element_is_separate_text_block = element.name.not_in? %W{
#               a abbr acronym b bdi bdo br code del dfn em font i img ins kbd mark
#               q s samp small span strike strong sub sup time tt u wbr
#             }
#             string_introduced_by_element =
#               case element.name
#               when "br" then "\n"
#               when "img" then " "
#               else ""
#               end
#             start_new_text_block.() if element_is_separate_text_block
#             text_blocks.last.concat(string_introduced_by_element)
#             element.children.each(&this)
#             start_new_text_block.() if element_is_separate_text_block
#           end
#         else
#           start_new_text_block.()
#         end
#       end
#       this.(element)
#       return text_blocks
#     end
#     
#     class URLs
#       
#       def initialize(web_search_results)
#         @web_search_results = web_search_results
#         @current_index = 0
#       end
#       
#       def current
#         @web_search_results[@current_index].url
#       end
#       
#       def next!
#         @current_index += 1
#         nil
#       end
#       
#     end
#     
#   end

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
    # 
    sloch = Regexp.new(
      sloch.
        downcase.
        gsub(/#{WHITESPACE}+/o, " ").strip.
        split("*").map { |part| Regexp.escape(part) }.join("*").
        gsub("*", "#{WORD}(( ?,? ?)#{WORD})?")
    ).d
    m = Memory.new
    #
#     web_search.(%("#{sloch}"), browser).
#       # Read page content and split it to text blocks.
#       lazy_cached_filter do |r|
#         text_blocks_from_page_at r.url
#       end.
    ["Everybody do the flop!
      o-ne t$w'o, do it, again flop three - fo-ur.
      ONE TWO DO IT AGAI'N FLOP THREE FO-UR...
      ONE TWO DO IT AGAI'N FLOP THREE Fo-ur...
      one two everydo it floppy disk three four.
      Very very very very very very very very very very very very very 
      very very very very very long phrase, do the flop included anyway.
    "].
      lazy_cached_filter do |text_block|
        text_block.
          #
          gsub(/#{WHITESPACE}+/o, " ").
          # 
          scan(/(#{WORD}(#{PUNCTUATION_OR_WS}+#{WORD})+)/o).map { |x| x.first }.
          #
          select do |phrase|
            words = phrase.d.scan(/#{WORD}/o).map { |x| x.first }
            phrase_downcase = phrase.downcase
            #
            m.not_mentioned_before?(phrase_downcase).d and
            # 
            (words.size <= 20).d and
            # 
            (not words.all? { |word| upcase?(word) }).d and
            # 
            (sloch =~ phrase_downcase).d and
            # two words must be before and after sloch
            (phrase_downcase.split(sloch).all? { |part| part.scan(/#{WORD}/o).size >= 2 }).d
          end
      end
  end
  
  private
  
  class ::Object
    
    def d(msg = nil)
      puts "#{if msg then "#{msg}: " else "" end}#{self.inspect}"
      return self
    end
    
  end
  
  WHITESPACE = "[\u0009-\u000D\u0020\u0085\u00A0\u1680\u180E\u2000-\u200A\u2028\u2029\u202F\u205F\u3000]"
  
  DOWNCASE_LETTER = "[a-z]"
  LETTER_OR_DIGIT = "[a-zA-Z0-9\\'\\$]"
  HYPHEN = "\\-"
  WORD = "([Ee]\\. ?g\\.|etc\\.|i\\. ?e\\.|[Ss]mb\\.|[Ss]mth\\.|(#{LETTER_OR_DIGIT}+(#{HYPHEN}+#{LETTER_OR_DIGIT}+)*))"
  PUNCTUATION_OR_WS = "[,\\- ]"
  
  def self.upcase?(word)
    /#{DOWNCASE_LETTER}/o !~ word
  end
  
  # returns Array of String-s.
  def self.text_blocks_from_page_at(uri)
    #
    page_io =
      begin
        open(uri)
      rescue
        return []
      end
    #
    begin
      return text_blocks_from(Nokogiri::HTML(page_io))
    ensure
      page_io.close()
    end
  end
  
  # returns Array of String's.
  def self.text_blocks_from(element)
    text_blocks = []
    start_new_text_block = lambda do
      text_blocks.push("") if text_blocks.empty? or not text_blocks.last.empty?
    end
    this = lambda do |element|
      case element
      when Nokogiri::XML::CDATA, Nokogiri::XML::Text
        text_blocks.last.concat(element.content.scrub("_"))
      when Nokogiri::XML::Comment
        # Do nothing.
      when Nokogiri::XML::Document, Nokogiri::XML::Element
        if element.name.in? %W{ script style } then
          start_new_text_block.()
        else
          element_is_separate_text_block = element.name.not_in? %W{
            a abbr acronym b bdi bdo br code del dfn em font i img ins kbd mark
            q s samp small span strike strong sub sup time tt u wbr
          }
          string_introduced_by_element =
            case element.name
            when "br" then "\n"
            when "img" then " "
            else ""
            end
          start_new_text_block.() if element_is_separate_text_block
          text_blocks.last.concat(string_introduced_by_element)
          element.children.each(&this)
          start_new_text_block.() if element_is_separate_text_block
        end
      else
        start_new_text_block.()
      end
    end
    this.(element)
    return text_blocks
  end
  
  class Memory
    
    def initialize()
      @impl = Set.new
    end
    
    # 
    # returns false once for every +x+. In other cases it returns true.
    # 
    def mentioned_before?(x)
      if @impl.include? x then
        @impl.add x
        return true
      else
        return false
      end
    end
    
    # Inversion of #mentioned_before?().
    def not_mentioned_before?(x)
      not mentioned_before?(x)
    end
    
  end
  
end

Redgerra::search_phrase("do * flop", nil, nil).to_a.d("Result")
