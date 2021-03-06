# -*- encoding: utf-8 -*-
$:.push File.expand_path("../lib", __FILE__)
require "hugs/version"

Gem::Specification.new do |s|
  s.name        = "hugs"
  s.version     = Hugs::VERSION
  s.platform    = Gem::Platform::RUBY
  s.authors     = ["John Dewey", "Josh Kleinpeter"]
  s.email       = ["john@dewey.ws", "josh@kleinpeter.org"]
  s.homepage    = %q{http://github.com/retr0h/hugs}
  s.summary     = %q{Hugs net-http-persistent with convenient get, delete, post, and put methods.}

  s.rubyforge_project = "hugs"

  s.files         = `git ls-files`.split("\n")
  s.test_files    = `git ls-files -- {test,spec,features}/*`.split("\n")
  s.executables   = `git ls-files -- bin/*`.split("\n").map{ |f| File.basename(f) }
  s.require_paths = ["lib"]

  s.add_dependency "yajl-ruby", "~> 0.7.9"
  s.add_dependency "nokogiri", ">= 1.4.4"
  s.add_dependency "net-http-persistent", "~> 1.4.1"

  s.add_development_dependency "rake"
  s.add_development_dependency "webmock"
  s.add_development_dependency "minitest"
end
