
class String
  
  # 
  # converts all consecutive white space characters[1] to " ".
  # 
  # [1] as specified in "Unicode Standard Annex #44: Unicode Character Database"
  # (http://www.unicode.org/reports/tr44, specifically
  # http://www.unicode.org/Public/UNIDATA/PropList.txt).
  # 
  def squeeze_unicode_whitespace()
    self.gsub(/[\u0009-\u000D\u0020\u0085\u00A0\u1680\u180E\u2000-\u200A\u2028\u2029\u202F\u205F\u3000]+/, " ")
  end
  
end