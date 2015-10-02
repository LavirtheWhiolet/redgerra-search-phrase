
Gem::Specification.new do |s|
  s.name = 'search-phrase'
  s.author = 'Lavir the Whiolet'
  s.email = 'Lavir.th.Whiolet@gmail.com'
  s.source_code = 'https://github.com/LavirtheWhiolet/search-phrase'
  s.homepage = s.source_code
  s.description = File.read("README.md")[
    /#{Regexp.escape("<!-- description -->")}(.*)#{Regexp.escape("<!-- end of description -->")}/, 1/
  ] or raise %(description is not found in "README.md")
  s.summary = s.description
  s.version = '0.0.6'
  s.license = 'Public Domain'
  s.description = <<-EOF
    Search for the specific phrase in Internet as specified by
    Redgerra. The library includes the searching function and
    a wrapper web-application for it.
  EOF
  s.files = Dir["lib/**/**"] + ["config.ru"]
  s.bindir = "bin"
  s.executables = Dir["bin/**/**"].map { |f| f["bin/".length..-1] }
  s.required_ruby_version = '>= 1.9.3'
  s.add_runtime_dependency 'nokogiri'
  s.add_runtime_dependency 'sinatra'
  s.add_runtime_dependency 'timers'
  s.add_runtime_dependency 'mechanize'
end
