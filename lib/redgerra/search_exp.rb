require 'redgerra/string/parse'
require 'string/hex_encode'
require 'redgerra/text'

module Redgerra
  
  # Redgerra::SearchExp is a regular expression with the following syntax:
  # 
  # - #escape(str) matches +str+.
  # - WORD matches any word.
  # - ASTERISK matches 1 or 2 words, any number of " " and one optional ","
  #   between them.
  # - All combinators from Regexp ("()", "{}", "x*", "x+", "x?" etc.) have
  #   the same meaning as in Regexp.
  # - It may include OCCURENCE, see Text#scan().
  # 
  # Example:
  #   
  #   SearchExp.new(
  #     "#{SearchExp::escape("do", false)} #{SearchExp::ASTERISK} #{SearchExp::escape("flop", false)}"
  #   )
  # 
  class SearchExp
    
    # Private for SearchExp.
    # 
    # Macro. See source code.
    # 
    def self.oo(str)
      "O#{str.hex_encode}O"
    end
    
    def self.escape(str, case_sensitive = true)
      str.parse do |token, type|
        case type
        when :word
          if case_sensitive then
            raise "not implemented"
          else
            "W#{token.downcase.hex_encode}Y\\h+W"
          end
        when :other
          oo(token)
        end
      end
    end
    
    WORD = "W\\h+Y\\h+W"
    
    ASTERISK = "#{WORD}(?:(?:#{oo ' '})?(?:#{oo ','})?(?:#{oo ' '})?#{WORD})?"
    
    OCCURENCE = "S\\h+S"
    
    def initialize(str)
      @encoded_regexp_str = str
    end
    
    # Accessible to Text only.
    # 
    # It returns String.
    # 
    attr_reader :encoded_regexp_str
    
  end
  
end
