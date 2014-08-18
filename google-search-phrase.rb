# encoding: UTF-8
gem 'nokogiri'
gem 'watir'
require 'nokogiri'

class String
  
  def lchomp(prefix)
    if self.start_sith? prefix
      self[prefix.length..-1]
    else
      self
    end
  end
  
end

browser = Watir::Browser.new(:phantomjs, "--ignore-ssl-errors=yes")
browser.goto "google.com"
b.text_field("q").set(ARGV[0])
b.button(name: "btnG").click()
doc = Nokogiri::HTML(b.html)
doc.xpath("//div[@id='ires']/ol/li/h3/a/@href").
  map(&:value).
  reject { |url| url.start_with? "/images" }.
  map { |url| url.lchomp("/url?q=") }
