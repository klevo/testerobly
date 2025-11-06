# frozen_string_literal: true

Gem::Specification.new do |spec|
  spec.name        = "testerobly"
  spec.version     = "1.1.0"
  spec.summary     = "Test runner to launch alongside your developer session for immediate feedback"
  spec.description = ""
  spec.authors     = ["Robert Starsi"]
  spec.email       = "klevo@klevo.sk"
  spec.homepage    = "https://github.com/klevo/testerobly"
  spec.license     = "MIT"

  spec.files = Dir["lib/**/*", "LICENSE"]
  spec.executables = %w[ testerobly ]

  spec.add_dependency "listen", "~> 3.9.0"
end
