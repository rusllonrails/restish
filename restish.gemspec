# coding: utf-8
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'restish/version'

Gem::Specification.new do |spec|
  spec.name          = "restish"
  spec.version       = Restish::VERSION
  spec.authors       = ["Jiří Zajpt"]
  spec.email         = ["jirizajpt@buddybet.cz"]
  spec.description   = %q{Restish is a REST client library}
  spec.summary       = %q{Restish is a REST client library}
  spec.homepage      = ""
  spec.license       = "MIT"

  spec.files         = `git ls-files`.split($/)
  spec.executables   = spec.files.grep(%r{^bin/}) { |f| File.basename(f) }
  spec.test_files    = spec.files.grep(%r{^(test|spec|features)/})
  spec.require_paths = ["lib"]

  spec.add_development_dependency 'bundler', '~> 1.3'
  spec.add_development_dependency 'rake'
  spec.add_development_dependency 'rspec', '~> 2.8'
  spec.add_development_dependency 'rack-test'
  spec.add_dependency 'activesupport'
  spec.add_dependency 'activemodel'
  spec.add_dependency 'hashie'
  spec.add_dependency 'faraday'
  spec.add_dependency 'faraday_middleware'
  spec.add_dependency 'faraday-http-cache'
  spec.add_dependency 'multi_json'
end
