# encoding: UTF-8
require 'string/hex_encode'
require 'string/hex_decode'
require 'redgerra/string/parse'
require 'redgerra/sloch'

module Redgerra
  
  # Redgerra::Text is the same as String but with slightly different methods.
  class Text
    
    def initialize(str)
      @str = str
    end
    
    def to_s
      @str
    end
    
    # 
    # +sloch+ is Sloch.
    # 
    def scan(sloch)
      encode(@str).
        scan(Regexp.new("(#{sloch.encoded_regexp_str})").map(&:first).
        map { |part| Text.new(decode(part)) }
    end
    
    # 
    # +sloch+ is Sloch.
    # 
    def split(sloch)
      encode(@str).
        split(Regexp.new(sloch.encoded_regexp_str)).
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
