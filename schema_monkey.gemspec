# coding: utf-8
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'schema_monkey/version'

Gem::Specification.new do |spec|
  spec.name          = "schema_monkey"
  spec.version       = SchemaMonkey::VERSION
  spec.authors       = ["ronen barzel"]
  spec.email         = ["ronen@barzel.org"]
  spec.summary       = %q{Provides an internal API and module inclusion protocol to facilitate adding features to ActiveRecord}
  spec.description   = %q{Provides an internal API and module inclusion protocol to facilitate adding features to ActiveRecord}
  spec.homepage      = "https://github.com/SchemaPlus/schema_monkey"
  spec.license       = "MIT"

  spec.files         = `git ls-files -z`.split("\x0")
  spec.executables   = spec.files.grep(%r{^bin/}) { |f| File.basename(f) }
  spec.test_files    = spec.files.grep(%r{^(test|spec|features)/})
  spec.require_paths = ["lib"]

  spec.add_dependency "activerecord", "~> 4.2"
  spec.add_dependency "hash_keyword_args"
  spec.add_dependency "its-it"
  spec.add_dependency "key_struct"
  spec.add_dependency "middleware", "~> 0.1"

  spec.add_development_dependency "bundler", "~> 1.7"
  spec.add_development_dependency "rake", "~> 10.0"
  spec.add_development_dependency "rspec", "~> 3.0.0"
  spec.add_development_dependency "schema_dev", "~> 1.4"
  spec.add_development_dependency "simplecov"
  spec.add_development_dependency "simplecov-gem-profile"
end
