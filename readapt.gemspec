lib = File.expand_path("lib", __dir__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require "readapt/version"

Gem::Specification.new do |spec|
  spec.name          = "readapt"
  spec.version       = Readapt::VERSION
  spec.authors       = ["Fred Snyder"]
  spec.email         = ["fsnyder@castwide.com"]

  spec.summary       = 'A Ruby debugger for the Debug Adapter Protocol'
  spec.description   = 'Readapt is a Ruby debugger that natively supports the Debug Adapter Protocol. Features include next/step in/step out, local and global variable data, and individual thread control.'
  spec.homepage      = "https://castwide.com"
  spec.license       = "MIT"

  spec.metadata["homepage_uri"] = spec.homepage
  spec.metadata["source_code_uri"] = "https://github.com/castwide/readapt"
  spec.metadata["changelog_uri"] = "https://github.com/castwide/readapt/blob/master/CHANGELOG.md"

  # Specify which files should be added to the gem when it is released.
  # The `git ls-files -z` loads the files in the RubyGem that have been added into git.
  spec.files         = Dir.chdir(File.expand_path('..', __FILE__)) do
    `git ls-files -z`.split("\x0").reject { |f| f.match(%r{^(test|spec|features)/}) }
  end
  spec.bindir        = "exe"
  spec.executables   = spec.files.grep(%r{^exe/}) { |f| File.basename(f) }
  spec.require_paths = ["lib"]
  spec.extensions = ['ext/readapt/extconf.rb']

  spec.required_ruby_version = '>= 2.2'

  spec.add_dependency 'backport', '~> 1.1'
  spec.add_dependency 'thor', '~> 1.0'

  spec.add_development_dependency "rake", "~> 12.3"
  spec.add_development_dependency "rake-compiler", "~> 1.0"
  spec.add_development_dependency "rspec", "~> 3.0"
  spec.add_development_dependency 'simplecov', '~> 0.14'
end
