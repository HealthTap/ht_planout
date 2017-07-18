# coding: utf-8
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'ht_planout/version'

Gem::Specification.new do |spec|
  spec.name          = "ht_planout"
  spec.version       = PlanOut::VERSION
  spec.authors       = ["Jerry Uejio"]
  spec.email         = ["jerry.uejio@healthtap.com"]

  spec.summary       = %q{Full ruby port of Facebook's PlanOut}
  spec.description   = %q{Implementation of entire PlanOut experimentation framework by Facebook except for namespaces}
  spec.homepage      = "https://github.com/jerry-uejio/ht_planout"
  spec.license       = 'BSD-3-Clause'

  # Prevent pushing this gem to RubyGems.org. To allow pushes either set the 'allowed_push_host'
  # to allow pushing to a single host or delete this section to allow pushing to any host.
  if spec.respond_to?(:metadata)
    spec.metadata['allowed_push_host'] = "TODO: Set to 'http://mygemserver.com'"
  else
    raise "RubyGems 2.0 or newer is required to protect against " \
      "public gem pushes."
  end

  spec.files         = `git ls-files -z`.split("\x0").reject do |f|
    f.match(%r{^(test|spec|features)/})
  end
  spec.bindir        = "exe"
  spec.executables   = spec.files.grep(%r{^exe/}) { |f| File.basename(f) }
  spec.require_paths = ["lib"]

  spec.add_development_dependency "bundler", "~> 1.14"
  spec.add_development_dependency "rake", '~> 0.9'
  spec.add_development_dependency "rspec"

  spec.required_ruby_version = '~> 2'
end
