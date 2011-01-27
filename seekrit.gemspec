lib = File.expand_path('../lib/', __FILE__)
$:.unshift lib unless $:.include?(lib)

Gem::Specification.new do |s|
  s.name        = "seekrit"
  s.version     = "0.2.3"
  s.platform    = Gem::Platform::RUBY
  s.authors     = ["Paul Battley"]
  s.email       = ["pbattley@gmail.com"]
  s.homepage    = "http://github.com/threedaymonk/seekrit"
  s.summary     = "Password safe"
  s.description = "A password safe"
  s.add_dependency "highline"

  s.executables  = Dir["bin/**"].map { |f| File.basename(f) }
  s.files        = Dir["{bin,lib}/**/*"]
  s.require_path = 'lib'
end
