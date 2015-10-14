# encoding: UTF-8
require 'string/hex_encode'
require 'string/hex_decode'
require 'redgerra/string/parse'
require 'redgerra/search_exp'

module Redgerra
  
  # Redgerra::Text is the same as String but with different methods set.
  class Text
    
    def initialize(str)
      @str = str
    end
    
    def to_s
      @str
    end
    
    # :call-seq:
    #   scan(search_exp)
    #   scan(search_exp, used_as_search_exp_occurence)
    # 
    # +search_exp+ is a SearchExp.
    # 
    # +used_as_search_exp_occurence+ is a SearchExp.
    # 
    # In the 1st form it returns occurences of +search_exp+ from this Text.
    # 
    # In the 2nd form it returns occurences of +search_exp+ from this Text.
    # +search_exp+ may include SearchExp::OCCURENCE which is interpreted as
    # +used_as_search_exp_occurence+.
    # 
    # The 2nd form may be used for simplifying +search_exp+ and improving
    # testability.
    # 
    def scan(search_exp, used_as_search_exp_occurence = nil)
      if used_as_search_exp_occurence then
        encode(@str).
          gsub(used_as_search_exp_occurence.encoded_regexp_str) do |o|
            "S#{o.hex_encode}S"
          end.
          scan(Regexp.new(search_exp.encoded_regexp_str)).
          map do |part|
            part.
              gsub(/S\h+S/) { |m| m[1...-1].hex_decode }.
              decode
          end
      else
        encode(@str).
          scan(Regexp.new("(#{search_exp.encoded_regexp_str})").map(&:first).
          map { |part| Text.new(decode(part)) }
      end
    end
    
    # 
    # +search_exp+ is SearchExp.
    # 
    def split(search_exp)
      encode(@str).
        split(Regexp.new(search_exp.encoded_regexp_str)).
        map { |part| Text.new(decode(part)) }
    end
    
    private
    
    # returns +str+ encoded in the following way:
    # 
    # - word → "W[01]\h+Y\h+W"
    # - other → "O\h+O"
    # 
    def encode(str)
      str.parse do |token, type|
        case type
        when :word
          is_proper_name_with_dot_flag =
            if token.include? "." then "1" else "0" end
          "W#{is_proper_name_with_dot_flag}#{token.downcase.hex_encode}Y#{token.hex_encode}W"
        when :other
          "O#{str.hex_encode}O"
        end
      end
    end
    
    def decode(str)
      str.gsub(/#{WORD}|#{OTHER}/o) do |match|
        case match[0]
        when "W"
          match[/Y(\h+)W/, 1].hex_decode
        when "O"
          match[1...-1].hex_decode
        end
      end
    end
    
  end
  
end
