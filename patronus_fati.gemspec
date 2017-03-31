# -*- encoding: utf-8 -*-

lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'patronus_fati/version'

Gem::Specification.new do |gem|
  gem.name          = "patronus_fati"
  gem.version       = PatronusFati::VERSION
  gem.authors       = [ "Sam Stelfox" ]
  gem.license       = "MIT"
  gem.email         = [ "sstelfox@bedroomprogrammers.net" ]
  gem.description   = %q{ A ruby implementation of the Kismet client protocol. }
  gem.summary       = %q{ A ruby implementation of the Kismet client protocol. }
  gem.homepage      = ""

  gem.files         = `git ls-files`.split($/)
  gem.executables   = gem.files.grep(%r{^bin/}).map{ |f| File.basename(f) }
  gem.test_files    = gem.files.grep(%r{^(test|spec|features)/})
  gem.require_paths = ["lib"]

  gem.add_dependency 'dm-constraints'
  gem.add_dependency 'dm-core'
  gem.add_dependency 'dm-migrations'
  gem.add_dependency 'dm-observer'
  gem.add_dependency 'dm-sqlite-adapter'
  gem.add_dependency 'dm-timestamps'
  gem.add_dependency 'dm-validations'
  gem.add_dependency 'louis', '~> 2.0'

  gem.add_development_dependency 'database_cleaner'
  gem.add_development_dependency 'dm-rspec'
  gem.add_development_dependency 'dm-transactions'
  gem.add_development_dependency 'rake'
  gem.add_development_dependency 'rdoc'
  gem.add_development_dependency 'pry'
  gem.add_development_dependency 'redcarpet'
  gem.add_development_dependency 'rspec'
  gem.add_development_dependency 'simplecov'
  gem.add_development_dependency 'yard'
end
