# -*- encoding: utf-8 -*-

lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'patronus_fati/version'

Gem::Specification.new do |gem|
  gem.name          = "patronus_fati"
  gem.version       = PatronusFati::VERSION
  gem.authors       = [ "Sam Stelfox" ]
  gem.license       = "LGPL"
  gem.email         = [ "sstelfox@bedroomprogrammers.net" ]
  gem.description   = %q{ A ruby implementation of the Kismet client protocol. }
  gem.summary       = %q{ A ruby implementation of the Kismet client protocol. }
  gem.homepage      = ""

  gem.files         = `git ls-files`.split($/)
  gem.executables   = gem.files.grep(%r{^bin/}).map{ |f| File.basename(f) }
  gem.test_files    = gem.files.grep(%r{^(test|spec|features)/})
  gem.require_paths = ["lib"]
end
