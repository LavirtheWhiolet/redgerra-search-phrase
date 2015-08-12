
Gem::Specification.new do |s|
  s.author = 'Lavir the Whiolet'
  s.email = 'Lavir.th.Whiolet@gmail.com'
  s.homepage = 'https://github.com/LavirtheWhiolet/search-phrase'
  s.files = Dir["lib/**/**"] + ["config.ru"]
  s.name = 'search-phrase'
  s.summary = 'Search for the specific phrase in Internet.'
  s.version = '0.0.3'
  s.license = 'Public Domain'
  s.description = <<-EOF
    Search for the specific phrase in Internet. The library includes the
    searching function and a wrapper web-application for it.
  EOF
  s.required_ruby_version = '>= 1.9.3'
  s.add_runtime_dependency 'nokogiri'
  s.add_runtime_dependency 'watir-webdriver'
  s.add_runtime_dependency 'sinatra'
  s.add_runtime_dependency 'timers'
  s.add_runtime_dependency 'headless'
  s.requirements << 'Firefox (https://www.mozilla.org/firefox)'
  s.requirements << 'Xvfb (http://www.x.org/releases/X11R7.6/doc/man/man1/Xvfb.1.xhtml)'
end
