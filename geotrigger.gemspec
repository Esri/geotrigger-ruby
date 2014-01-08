# -*- encoding: utf-8 -*-
require File.expand_path('../lib/geotrigger/version', __FILE__)

Gem::Specification.new do |gem|
  gem.authors       = ["Kenichi Nakamura"]
  gem.email         = ["kenichi.nakamura@gmail.com"]
  gem.description   = gem.summary = "A small ruby client for Esri's Geotrigger service"
  gem.homepage      = "https://github.com/esripdx/geotrigger-ruby"
  gem.files         = `git ls-files | grep -Ev '^(myapp|examples)'`.split("\n")
  gem.test_files    = `git ls-files -- spec/*`.split("\n")
  gem.name          = "geotrigger"
  gem.require_paths = ["lib"]
  gem.version       = Geotrigger::VERSION
  gem.license       = 'apache'

  gem.add_dependency 'httpclient'
  gem.add_development_dependency 'timecop'
  gem.add_development_dependency 'rspec'
  gem.add_development_dependency 'pry'
end
