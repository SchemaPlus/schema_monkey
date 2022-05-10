# frozen_string_literal: true

lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'schema_monkey/version'

Gem::Specification.new do |spec|
  spec.name          = "schema_monkey"
  spec.version       = SchemaMonkey::VERSION
  spec.authors       = ["ronen barzel"]
  spec.email         = ["ronen@barzel.org"]
  spec.summary       = %q{Provides a module insertion protocol to facilitate adding features to ActiveRecord}
  spec.description   = %q{Provides a module insertion protocol to facilitate adding features to ActiveRecord}
  spec.homepage      = "https://github.com/SchemaPlus/schema_monkey"
  spec.license       = "MIT"

  spec.files         = `git ls-files -z`.split("\x0")
  spec.executables   = spec.files.grep(%r{^bin/}) { |f| File.basename(f) }
  spec.test_files    = spec.files.grep(%r{^(test|spec|features)/})
  spec.require_paths = ["lib"]

  spec.required_ruby_version = ">= 2.5.0"

  spec.add_dependency "activerecord", ">= 5.2"
  spec.add_dependency "modware", "~> 1.0.2"

  spec.add_development_dependency "bundler"
  spec.add_development_dependency "rake", "~> 13.0"
  spec.add_development_dependency "rspec", "~> 3.0"
  spec.add_development_dependency "rspec-given", "~> 3.6"
  spec.add_development_dependency "schema_dev", "~> 4.2.beta.1"
end
