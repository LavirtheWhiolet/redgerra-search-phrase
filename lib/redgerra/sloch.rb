require 'redgerra/string/parse'
require 'string/hex_encode'
require 'redgerra/text'

module Reggerra
  
  # Sloch is a regular expression with the following syntax:
  # 
  # - Sloch::escape(str) matches +str+.
  # - Sloch::WORD matches any word.
  # - Sloch::ASTERISK matches 1 or 2 words, any number of " " and one optional
  #   "," between them.
  # - All combinators from Regexp ("()", "{}", "x*", "x+", "x?") have the same
  #   meaning as in Regexp.
  # 
  # Example:
  #   
  #   Sloch.new(
  #     "#{Sloch::escape("do", false)} #{Sloch::ASTERISK} #{Sloch::escape("flop", false)}"
  #   )
  # 
  class Sloch
    
    # Private for Sloch.
    # 
    # Macro. See source code.
    # 
    def self.oo(str)
      "O#{str.hex_encode}O"
    end
    
    def self.escape(str, case_sensitive = true)
      parse do |token, type|
        case type
        when :word
          if case_sensitive then
            raise "not implemented"
          else
            "W[01]#{token.downcase.hex_encode}Y\\h+W"
          end
        when :other
          oo(token)
        end
      end
    end
    
    WORD = "W[01]\\h+Y\\h+W"
    
    ASTERISK = "#{WORD}((#{oo ' '})?(#{oo ','})?(#{oo ' '})?#{WORD})?"
    
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
