# coding: utf-8
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'fragrance/version'

Gem::Specification.new do |spec|
  spec.name          = "fragrance"
  spec.version       = Fragrance::VERSION
  spec.authors       = ["Michael Lorant"]
  spec.email         = ["michael.lorant@fairfaxmedia.com.au"]

  spec.summary       = %q{Fragrance search all AWS ELBs for the instances and reregisters them if necessary.}
  spec.description   = %q{Fragrance search all AWS ELBs for the instances and reregisters them if necessary.}
  spec.homepage      = "https://bitbucket.org/fairfax"
  spec.license       = "MIT"

  spec.files         = `git ls-files -z`.split("\x0").reject { |f| f.match(%r{^(test|spec|features)/}) }
  spec.bindir        = "bin"
  spec.executables   = spec.files.grep(%r{^bin/}) { |f| File.basename(f) }
  spec.require_paths = ["lib"]

  spec.add_runtime_dependency "aws-sdk", "~> 2.0"

  spec.add_development_dependency "bundler", "~> 1.8"
  spec.add_development_dependency "rake", "~> 10.0"
  spec.add_development_dependency "pry", "~> 0.10"
end
