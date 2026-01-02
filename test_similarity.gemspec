# frozen_string_literal: true

require_relative "lib/test_similarity/version"

Gem::Specification.new do |spec|
  spec.name          = "test_similarity"
  spec.version       = TestSimilarity::VERSION
  spec.authors       = ["Junya Ogino"]
  spec.email         = ["ogijun@gmail.com"]

  spec.summary       = "Observe how similar your tests are"
  spec.description   = "Records execution signatures of tests to help you notice similarity, without judging or enforcing anything."
  spec.homepage      = "https://github.com/ogijun/test_similarity"
  spec.license       = "MIT"

  spec.required_ruby_version = ">= 2.7"

  spec.files         = Dir["lib/**/*", "README.md", "LICENSE"]
  spec.require_paths = ["lib"]

  spec.add_development_dependency "minitest"
end
