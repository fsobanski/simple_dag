Gem::Specification.new do |s|
  s.name        = 'simple_dag'
  s.version     = '0.0.0'
  s.license     = 'MIT'
  s.summary     = 'Simple directed acyclic graphs'
  s.description = 'A simple library for working with directed acyclic graphs'
  s.authors     = ['Kevin Rutherford', 'Fabian Sobanski']
  s.homepage    = 'https://github.com/fsobanski/simple_dag'

  s.add_development_dependency 'rake', '~> 10'
  s.add_development_dependency 'rspec', '~> 3'

  s.files          = `git ls-files -- lib spec [A-Z]* .rspec .yardopts`.split("\n")
  s.test_files     = `git ls-files -- spec`.split("\n")
  s.require_path   = 'lib'
end
