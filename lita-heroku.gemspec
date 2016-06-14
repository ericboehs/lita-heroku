Gem::Specification.new do |spec|
  spec.name          = "lita-heroku"
  spec.version       = "0.1.10"
  spec.authors       = ["Eric Boehs"]
  spec.email         = ["ericboehs@gmail.com"]
  spec.description   = "Lita handler for interacting with Heroku Apps"
  spec.summary       = "Lita handler for interacting with Heroku Apps"
  spec.homepage      = "https://github.com/ericboehs/lita-heroku"
  spec.license       = "MIT"
  spec.metadata      = { "lita_plugin_type" => "handler" }

  spec.files         = `git ls-files`.split($/)
  spec.executables   = spec.files.grep(%r{^bin/}) { |f| File.basename(f) }
  spec.test_files    = spec.files.grep(%r{^(test|spec|features)/})
  spec.require_paths = ["lib"]

  spec.add_runtime_dependency "lita", ">= 4.7"

  spec.add_development_dependency "bundler", "~> 1.3"
  spec.add_development_dependency "pry-byebug"
  spec.add_development_dependency "rake"
  spec.add_development_dependency "rack-test"
  spec.add_development_dependency "rspec", ">= 3.0.0"
end
