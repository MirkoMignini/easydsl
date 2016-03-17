# coding: utf-8
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'opendsl/version'

Gem::Specification.new do |spec|
  spec.name          = 'opendsl'
  spec.version       = Opendsl::VERSION
  spec.authors       = ['Mirko Mignini']
  spec.email         = ['mirko.mignini@gmail.com']

  spec.summary       = 'OpenDSL allows you to create your own ruby dsl'\
                       ' without writing a single line of code.'
  spec.homepage      = 'https://github.com/MirkoMignini/opendsl'
  spec.license       = 'MIT'
  spec.files         = `git ls-files -z`.split("\x0")
                                        .reject { |f| f.match(%r{^(test|spec|features)/}) }
  spec.bindir        = 'exe'
  spec.executables   = spec.files.grep(%r{^exe/}) { |f| File.basename(f) }
  spec.require_paths = ['lib']

  spec.add_development_dependency 'bundler', '~> 1.10'
  spec.add_development_dependency 'rake', '~> 10.0'
  spec.add_development_dependency 'rspec'
  spec.add_development_dependency 'coveralls'
  spec.add_development_dependency 'rubocop'
  spec.add_development_dependency 'rubocop-rspec'

  spec.add_dependency 'activesupport', '~> 4.2.6'
end
