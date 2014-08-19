# encoding: UTF-8
gem 'nokogiri'
gem 'watir'
require 'nokogiri'
require 'watir'

class String
  
  def lchomp(prefix)
    if self.start_with? prefix
      self[prefix.length..-1]
    else
      self
    end
  end
  
end

browser = Watir::Browser.new(:phantomjs, args: ["--ignore-ssl-errors=yes"])
browser.goto "google.com"
browser.text_field(name: "q").set("\"#{ARGV[0]}\"")
browser.button(name: "btnG").click()
File.write("response.html", browser.html)
doc = Nokogiri::HTML(browser.html)
doc.xpath("//div[@id='ires']/ol/li/h3/a/@href").
  map(&:value).
  reject { |url| url.start_with? "/images" }.
  map { |url| url.lchomp("/url?q=") }