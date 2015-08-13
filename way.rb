require 'open-uri'
require 'cgi'
require 'nokogiri'

opts = { "User-Agent" => "PhantomJS/1.9.8" }

begin
  open(ARGV[0], opts) { |io| File.write("h.html", io.read) }
rescue Exception => e
  File.write("h.html", e.io.read)
  e.io.close()
end
html = Nokogiri::HTML(File.read("h.html"));
image = html.xpath("//img/@src").first.value
puts image
open("https://google.com#{image}", opts) { |io| File.write("c.jpg", io.read) }
print "Captcha: "
captcha = STDIN.gets.chomp
cont = html.xpath("//input[@name='continue']/@value").first.value
id = html.xpath("//input[@name='id']/@value").first.value
submit = html.xpath("//input[@name='submit']/@value").first.value
url = "https://ipv4.google.com/sorry/CaptchaRedirect?continue=#{CGI::escape cont}&id=#{CGI::escape id}&captcha=#{CGI::escape captcha}&submit=#{CGI::escape submit}"
puts url
begin
  open(url, opts) { |io| File.write(ARGV[1], io.read) }
rescue Exception => e
  puts e.message
  File.write("h.html", e.io.read)
  e.io.close()
end
