# coding: utf-8
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'sensu_generator/version'

Gem::Specification.new do |spec|
  spec.name          = "sensu_generator"
  spec.version       = SensuGenerator::VERSION
  spec.authors       = ["Grigory Aksentyev"]
  spec.email         = ["grigory.aksentiev@gmail.com"]

  spec.summary       = %q{Sensu check config generator}
  spec.description   = %q{Generate sensu check configurations within consul state.}
  spec.homepage      = "https://github.com/aksentyev/sensu_generator"

  spec.files         = `git ls-files -z`.split("\x0").reject { |f| f.match(%r{^(test|spec|features)/}) }
  spec.bindir        = "exe"
  spec.executables   = spec.files.grep(%r{^exe/}) { |f| File.basename(f) }
  spec.require_paths = ["lib"]

  spec.add_dependency 'diplomat'
  spec.add_dependency 'slack-notifier'
  spec.add_dependency 'ruby-supervisor'
  spec.add_dependency 'rsync'
  spec.add_dependency 'daemons'

  spec.add_development_dependency "pry"
  spec.add_development_dependency "bundler", "~> 1.11"
  spec.add_development_dependency "rake", "~> 10.0"
  spec.add_development_dependency "rspec", "~> 3.0"
end
