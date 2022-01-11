require_relative "lib/polyssh/version"

Gem::Specification.new do |spec|
  spec.name          = "polyssh"
  spec.version       = Polyssh::VERSION
  spec.authors       = ["labocho"]
  spec.email         = ["labocho@penguinlab.jp"]

  spec.summary       = "polyssh runs command on multiple remote servers via ssh with friendly TUI."
  spec.description   = "polyssh runs command on multiple remote servers via ssh with friendly TUI."
  spec.homepage      = "https://github.com/socioart/polyssh"
  spec.license       = "MIT"
  spec.required_ruby_version = Gem::Requirement.new(">= 3.1")

  spec.metadata["homepage_uri"] = spec.homepage
  spec.metadata["source_code_uri"] = spec.homepage
  spec.metadata["changelog_uri"] = "https://github.com/socioart/polyssh/blob/master/CHANGELOG.md"

  # Specify which files should be added to the gem when it is released.
  # The `git ls-files -z` loads the files in the RubyGem that have been added into git.
  spec.files = Dir.chdir(File.expand_path(__dir__)) do
    `git ls-files -z`.split("\x0").reject {|f| f.match(%r{^(test|spec|features)/}) }
  end
  spec.bindir        = "exe"
  spec.executables   = spec.files.grep(%r(^exe/)) {|f| File.basename(f) }
  spec.require_paths = ["lib"]
  spec.metadata["rubygems_mfa_required"] = "true"

  spec.add_dependency "tty-cursor", "~> 0.7.1"
  spec.add_dependency "tty-table", "~> 0.12.0"
end
