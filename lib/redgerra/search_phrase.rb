# encoding: UTF-8
require 'strscan'
require 'object/in'
require 'web_search_result'
require 'web_search_error'
require 'random_accessible'
require 'set'
require 'string/squeeze_unicode_whitespace'
require 'monitor'
require 'object/not_empty'

# For Redgerra::search_phrase_in_files().
require 'find'

# For Redgerra::text_blocks_from() and Redgerra::text_blocks_from_page_at().
require 'open-uri'
require 'nokogiri'
require 'object/not_in'
require 'string/scrub'
require 'timeout'

module Redgerra
  
  # 
  # searches for phrases in +dirs_or_files+ which include +sloch+.
  # 
  # It returns Enumerable of Error-s and String-s.
  # 
  def self.search_phrase_in_files(sloch, dirs_or_files)
    SearchPhraseInFiles.new(sloch, dirs_or_files)
  end
  
  # 
  # searches for phrases in WWW which include +sloch+.
  # 
  # +web_search+ is a Proc which queries a web search engine (such as Yandex,
  # Google, DuckDuckGo or other). It is passed with:
  # - the query;
  # - preferred language (a two-letter code, e. g.: "en", "ru", fr");
  # - +browser+.
  # 
  # +web_search+ must return RandomAccessible collection of WebSearchResult-s.
  # The collection's RandomAccessible#[] may raise WebSearchError.
  # 
  # +timeout_per_page+ is timeout per each web-page this function visits.
  # 
  # This method returns thread-safe RandomAccessible collection of String-s.
  # The collection's RandomAccessible#[] may raise WebSearchError.
  # 
  def self.search_phrase(sloch, web_search, browser, timeout_per_page = 30)
    # 
    m = Memory.new
    # 
    phrases =
      web_search.(%("#{sloch}"), "en", browser).
      lazy_cached_filter do |web_search_result|
        text_blocks_from_page_at(web_search_result.url, timeout_per_page)
      end.
      lazy_cached_filter do |text_block|
        phrases_from(text_block, sloch).
          reject { |phrase| m.mentioned_before?(phrase.downcase.chomp("'")) }
      end
    #
    return ThreadSafeRandomAccessible.new(phrases)
  end
  
  Error = Struct.new :message
  
  private
  
  def self.phrases_from(str, sloch)
    # 
    str = str.squeeze_unicode_whitespace
    sloch = sloch.squeeze_unicode_whitespace
    # 
    text = Text.new(str)
    # 
    sloch = SearchExp.new(
      sloch.split("*", -1).
      map { |part| esc(part, false) }.
      join(SearchExp::ASTERISK)
    )
    # 
    phrases =
      # Search for all phrases.
      text.scan(
        SearchExp.new("(?:#{WORD}#{PUNCT_AND_WS}){,10}(?:#{esc '"'}#{PUNCT_AND_WS}(?:#{WORD}#{PUNCT_AND_WS}){,10})?#{SLOCH_OCCURENCE}(?:#{PUNCT_AND_WS}(?:#{WORD}|#{SLOCH_OCCURENCE})){,10}#{FINAL_PUNCT}"),
        sloch
      ).
      # There must be another words except sloch.
      select do |phrase|
        phrase.split(sloch).any? do |part|
          part.scan(SearchExp.new(WORD)).not_empty?
        end
      end.
      # Reject phrases with proper names with "." (e. g. "file.mp3").
      reject do |phrase|
        phrase.scan(SearchExp.new(WORD)).any? do |word|
          word.to_s.include? "."
        end
      end.
      # 
      reject { |phrase| phrase.to_s.upcase? }.
      # Strip the phrases from unwanted characters.
      map do |phrase|
        phrase.to_s.gsub(/^[, ]+|[, ]+$/, "")
      end
    #
    return phrases
  end
  
  # --------------------------------------------
  # :section: Accessible to #phrases_from() only
  # --------------------------------------------
  
  def self.esc(str)
    SearchExp.escape(str)
  end
  
  SLOCH_OCCURENCE = SearchExp::OCCURENCE
  WORD = SearchExp::WORD
  PUNCT_AND_WS = "(?:#{esc ','}|#{esc ' '})*"
  FINAL_PUNCT = "(?:#{esc '!'}|#{esc '?'}|#{esc '.'}|#{esc ';'}|#{esc '…'})*"
  
  # ---------
  # :section:
  # ---------
  
  # Private for Redgerra and its nested classes and modules.
  # 
  # It returns Array of String-s.
  # 
  def self.text_blocks_from_page_at(uri, timeout)
    #
    page_io =
      begin
        Timeout::timeout(timeout) { open(uri) }
      rescue
        return []
      end
    #
    begin
      text_blocks_from(Nokogiri::HTML(page_io))
    ensure
      page_io.close()
    end
  end
  
  # Private for Redgerra and its nested classes and modules.
  # 
  # It returns Array of String-s.
  # 
  # +element+ is Nokogiri::Element.
  # 
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
  
  # Private for Redgerra and its nested classes and modules.
  # 
  # It returns Array of String-s.
  # 
  def self.text_blocks_from_plain_text(plain_text)
    plain_text.scrub.split(/\n{2,}/)
  end
  
  class ThreadSafeRandomAccessible
    
    include RandomAccessible
    include MonitorMixin
    
    def initialize(source)
      super()
      @source = source
    end
    
    def [](index)
      mon_synchronize do
        @source[index]
      end
    end
    
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
        return true
      else
        @impl.add x
        return false
      end
    end
    
  end
  
  class SearchPhraseInFiles
    
    include Enumerable
    
    def initialize(sloch, dirs_or_files)
      @sloch = sloch
      @dirs_or_files = dirs_or_files
    end
    
    def each
      for dir_or_file in @dirs_or_files
        begin
          Find.find(dir_or_file) do |entry|
            next unless File.file? entry
            file = entry
            begin
              phrases = text_blocks_from(file).
                filter2 { |text_block| Redgerra.phrases_from(text_block, @sloch) }.
                each { |phrase| yield phrase }
            rescue Exception => e
              yield Error.new %("#{file}": #{e.message})
            end
          end
        rescue Errno::ENOENT
          yield Error.new %("#{dir_or_file}" does not exist)
        end
      end
    end
    
    private
    
    def text_blocks_from(file)
      case File.extname(file)
      when ".txt"
        Redgerra.text_blocks_from_plain_text(File.read(file))
      when ".htm", ".html"
        Redgerra.text_blocks_from(Nokogiri::HTML(File.read(file)))
      else
        raise FormatUnsupported.new
      end
    end
    
    class FormatUnsupported < Exception
      
      def initialize()
        super("file format is unsupported")
      end
      
    end
    
  end
  
end
