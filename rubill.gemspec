# coding: utf-8
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'rubill'

Gem::Specification.new do |spec|
  spec.name          = "rubill"
  spec.version       = Rubill::VERSION
  spec.authors       = ["Rick Frankel"]
  spec.email         = ["rick@rickster.com"]

  spec.summary       = %q{An time tracker and invoice generator for OS X}
  #spec.homepage      = "TODO: Put your gem's website or public repo URL here."

  spec.files         = `git ls-files -z`.split("\x0").reject { |f| f.match(%r{^(test|spec|features)/}) }
  spec.bindir        = "exe"
  spec.executables   = spec.files.grep(%r{^exe/}) { |f| File.basename(f) }
  spec.require_paths = ["lib"]

  spec.add_dependency "prawn", "~> 2.0"
  spec.add_dependency "prawn-table", "~> 0.2"
  spec.add_dependency "rb-appscript", "~> 0.6.1"

  spec.add_development_dependency "bundler", "~> 1.9"
  spec.add_development_dependency "rake", "~> 10.0"
end
