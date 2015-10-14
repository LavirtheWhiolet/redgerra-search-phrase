require 'redgerra/text'

module Reggerra
  
  # Redgerra::Sloch is a regular expression with non-standard syntax:
  # - #escape(str) matches +str+
  # - 
  # 
  # 
  class Sloch
    
    def self.escape(str, case_sensitive = true)
      Text.encode(str)
    end
    
    def self.word
    end
    
    private
    
    def initialize(regexp)  # :not-new:
      @regexp = regexp
    end
    
  end
  
end