# -*- encoding: utf-8 -*-
require File.expand_path('../lib/atom/version', __FILE__)

Gem::Specification.new do |s|
  s.name = "ratom-nokogiri"
  s.version = Atom::VERSION

  s.authors = ["Peerworks", "Sean Geoghegan", "Brian Palmer"]
  s.description = "A fast Atom Syndication and Publication API based on libxml"
  s.email = "eng@instructure.com"
  s.extra_rdoc_files = [
    "LICENSE",
    "README.rdoc"
  ]
  s.files         = `git ls-files`.split($\)
  s.executables   = s.files.grep(%r{^bin/}).map{ |f| File.basename(f) }
  s.test_files    = s.files.grep(%r{^(test|spec|features)/})
  s.homepage = "http://github.com/instructure/ratom"
  s.require_paths = ["lib"]
  s.summary = "Atom Syndication and Publication API"

  s.add_dependency(%q<nokogiri>, [">= 1.5.6", "< 1.12"])
  s.add_development_dependency(%q<bundler>, ["~> 1.1"])
  s.add_development_dependency(%q<rspec>, ["~> 3.6.0"])
  s.add_development_dependency(%q<rake>, ["~> 12.0"])
  s.add_development_dependency(%q<byebug>, ["~> 10.0"])
end

