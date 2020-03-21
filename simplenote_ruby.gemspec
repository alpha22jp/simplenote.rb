require_relative 'lib/simplenote_ruby/version'

Gem::Specification.new do |spec|
  spec.name          = "simplenote_ruby"
  spec.version       = SimplenoteRuby::VERSION
  spec.authors       = ["alpha22jp"]
  spec.email         = ["alpha22jp@gmail.com"]

  spec.summary       = %q{Ruby library to interact with Simplenote (https://app.simplenote.com/).}
  spec.homepage      = "https://github.com/alpha22jp/simplenote.rb"
  spec.license       = "MIT"
  spec.required_ruby_version = Gem::Requirement.new(">= 2.3.0")

  spec.metadata["homepage_uri"] = spec.homepage
  spec.metadata["source_code_uri"] = spec.homepage
  #spec.metadata["changelog_uri"] = "TODO: Put your gem's CHANGELOG.md URL here."

  # Specify which files should be added to the gem when it is released.
  # The `git ls-files -z` loads the files in the RubyGem that have been added into git.
  spec.files         = Dir.chdir(File.expand_path('..', __FILE__)) do
    `git ls-files -z`.split("\x0").reject { |f| f.match(%r{^(test|spec|features)/}) }
  end
  spec.bindir        = "exe"
  spec.executables   = spec.files.grep(%r{^exe/}) { |f| File.basename(f) }
  spec.require_paths = ["lib"]

  spec.add_dependency "httparty"
  spec.add_dependency "http-exceptions"
  #spec.add_dependency "base64"
  spec.add_dependency "uuid"
end
