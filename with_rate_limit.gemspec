require_relative 'lib/with_rate_limit/version'

Gem::Specification.new do |spec|
  spec.name          = "with_rate_limit"
  spec.version       = WithRateLimit::VERSION
  spec.authors       = ["Aleksandr Terletskiy"]
  spec.email         = ["aterletskiy@gmail.com"]

  spec.summary       = %q{Rate limits operations that are passed in to block}
  spec.description   = %q{Allows operations that are passed into `with_rate_limit` block to be rate limited}
  spec.homepage      = "https://github.com/aterletskiy/with-rate-limit"
  spec.license       = "MIT"
  spec.required_ruby_version = Gem::Requirement.new(">= 2.3.0")

  # spec.metadata["allowed_push_host"] = "http://mygemserver.com"

  spec.metadata["homepage_uri"] = spec.homepage
  spec.metadata["source_code_uri"] = "https://github.com/aterletskiy/with-rate-limit"
  spec.metadata["changelog_uri"] = "https://github.com/aterletskiy/with_rate_limit/CHANGELOG.md"

  # Specify which files should be added to the gem when it is released.
  # The `git ls-files -z` loads the files in the RubyGem that have been added into git.
  spec.files         = Dir.chdir(File.expand_path('..', __FILE__)) do
    `git ls-files -z`.split("\x0").reject { |f| f.match(%r{^(test|spec|features)/}) }
  end
  spec.bindir        = "exe"
  spec.executables   = spec.files.grep(%r{^exe/}) { |f| File.basename(f) }
  spec.require_paths = ["lib"]
end
