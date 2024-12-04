lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'json_data_extractor/version'

Gem::Specification.new do |spec|
  spec.name    = 'json_data_extractor'
  spec.version = JsonDataExtractor::VERSION
  spec.authors = ['Max Buslaev']
  spec.email   = ['max@buslaev.net']

  spec.summary     = %q{Transform JSON data structures with the help of a simple schema and JsonPath expressions.
Use the JsonDataExtractor gem to extract and modify data from complex JSON structures using a straightforward syntax
and a range of built-in or custom modifiers.}
  spec.description = %q{json_data_extractor makes it easy to extract data from complex JSON structures,
such as API responses or configuration files, using a schema that defines the path to the data and any necessary
transformations. The schema is defined as a simple Ruby hash that maps keys to paths and optional modifiers.}
  spec.homepage    = 'https://github.com/austerlitz/json_data_extractor'
  spec.license     = 'MIT'

  # Specify which files should be added to the gem when it is released.
  # The `git ls-files -z` loads the files in the RubyGem that have been added into git.
  spec.files         = Dir.chdir(File.expand_path('..', __FILE__)) do
    `git ls-files -z`.split("\x0").reject { |f| f.match(%r{^(test|spec|features)/}) }
  end
  spec.bindir        = 'exe'
  spec.executables   = spec.files.grep(%r{^exe/}) { |f| File.basename(f) }
  spec.require_paths = ['lib']

  spec.add_development_dependency 'bundler'
  spec.add_development_dependency 'rake', '~> 10.0'
  spec.add_development_dependency 'rspec', '~> 3.0'
  spec.add_development_dependency 'pry'
  spec.add_development_dependency 'amazing_print'

  spec.add_dependency 'jsonpath'
end
